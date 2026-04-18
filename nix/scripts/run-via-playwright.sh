#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <script-name>" >&2
  exit 1
fi

script_name="$1"
script_path=""

for candidate in "scripts/$script_name" "scripts/$script_name.js"; do
  if [ -f "$candidate" ]; then
    script_path="$candidate"
    break
  fi
done

if [ -z "$script_path" ]; then
  echo "Script not found in scripts/: $script_name" >&2
  exit 1
fi

script_url="$(
  sed -n 's/.*Open URL:[[:space:]]*//p' "$script_path" |
    head -n1
)"

profile_dir="${JSONHUB_CHROME_USER_DATA_DIR:-$PWD/.jsonhub/chrome-profile}"
session_name="jsonhub-run-$$"
temp_dir="$PWD/.jsonhub/tmp"
mkdir -p "$temp_dir"
code_path="$(mktemp "$temp_dir/run-via-playwright.XXXXXX.js")"
prepared_script_path="$(mktemp "$temp_dir/run-via-playwright.source.XXXXXX.js")"
output_path="$(mktemp)"
error_path="$(mktemp)"
opened_session=0

cleanup() {
  rm -f "$code_path" "$prepared_script_path" "$output_path" "$error_path"
  if [ "$opened_session" -eq 1 ]; then
    bunx playwright-cli -s="$session_name" close >/dev/null 2>&1 || true
  fi
}

trap cleanup EXIT

profile_holders() {
  lsof -t +D "$profile_dir" 2>/dev/null | sort -u
}

has_running_chrome() {
  [ -n "$(profile_holders)" ]
}

print_profile_holders() {
  profile_holders |
    while read -r pid; do
      [ -n "$pid" ] || continue
      ps -p "$pid" -o pid=,comm=
    done
}

clear_stale_profile_lock() {
  find "$profile_dir" -maxdepth 1 \
    \( -name 'Singleton*' -o -name '.com.google.Chrome.*' \) \
    -exec rm -rf {} +
}

open_browser() {
  if bunx playwright-cli -s="$session_name" open "${script_url:-about:blank}" --profile "$profile_dir" > /dev/null 2>"$error_path"; then
    opened_session=1
    return 0
  fi

  if ! grep -Fq "Browser is already in use for $profile_dir" "$error_path"; then
    cat "$error_path" >&2
    return 1
  fi

  if has_running_chrome; then
    cat >&2 <<EOF
Chrome profile is already in use: $profile_dir
Profile holders:
$(print_profile_holders)
Close Chrome first, or attach directly with:
  bunx playwright-cli -s=jsonhub-cdp attach --cdp="http://127.0.0.1:$JSONHUB_CHROME_CDP_PORT"
EOF
    return 1
  fi

  clear_stale_profile_lock

  if bunx playwright-cli -s="$session_name" open "${script_url:-about:blank}" --profile "$profile_dir" > /dev/null 2>"$error_path"; then
    opened_session=1
    return 0
  fi

  cat "$error_path" >&2
  return 1
}

open_browser

# Browser scripts are pasted into DevTools as top-level code, so they end with
# an expression instead of `return ...`. Rewrite the last non-empty line to an
# explicit return before running it via AsyncFunction in Playwright.
awk '
  {
    lines[NR] = $0
    if ($0 ~ /[^[:space:]]/) last = NR
  }
  END {
    if (!last) {
      print "Script is empty" > "/dev/stderr"
      exit 1
    }
    expr = lines[last]
    match(expr, /^[[:space:]]*/)
    indent = substr(expr, 1, RLENGTH)
    sub(/^[[:space:]]+/, "", expr)
    sub(/[[:space:]]*;?[[:space:]]*$/, "", expr)
    lines[last] = indent "return (" expr ");"
    for (i = 1; i <= NR; i++) print lines[i]
  }
' "$script_path" > "$prepared_script_path"

script_json="$(jq -Rs . < "$prepared_script_path")"

cat >"$code_path" <<EOF
async (page) => {
  const source = $script_json;
  return await page.evaluate(async (source) => {
    const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
    return await new AsyncFunction(source)();
  }, source);
}
EOF

bunx playwright-cli -s="$session_name" --raw run-code --filename="$code_path" >"$output_path"
if [ ! -s "$output_path" ]; then
  echo "Playwright script returned no data. End the script with a final expression like JSON.stringify(...)." >&2
  exit 1
fi
if ! jq -e 'type == "string"' "$output_path" >/dev/null 2>&1; then
  cat "$output_path" >&2
  exit 1
fi
json_output="$(jq -r '.' "$output_path")"
printf '%s\n' "$json_output" | jq -e . >/dev/null
printf '%s\n' "$json_output" | jq .
