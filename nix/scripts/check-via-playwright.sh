#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <script-name>" >&2
  exit 1
fi

script_name="$1"
fixture_path="test/$script_name.contains.json"

if [ ! -f "$fixture_path" ]; then
  echo "Fixture not found: $fixture_path" >&2
  exit 1
fi

actual_path="$(mktemp)"
report_path="$(mktemp)"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -f "$actual_path" "$report_path"
  rm -rf "$tmp_dir"
}

trap cleanup EXIT

./nix/scripts/run-via-playwright.sh "$script_name" >"$actual_path"

jq -c '.[]' "$fixture_path" |
  while IFS= read -r fixture_item; do
    if jq -e --argjson fixture "$fixture_item" 'any(.[]; contains($fixture))' "$actual_path" >/dev/null; then
      continue
    fi

    label="$(
      jq -r '.link // .name // "<unknown item>"' <<<"$fixture_item"
    )"
    match="$(
      jq -c \
        --argjson fixture "$fixture_item" \
        '
          first(
            .[]
            | select(
                ($fixture.link != null and .link == $fixture.link)
                or ($fixture.name != null and .name == $fixture.name)
              )
          ) // empty
        ' \
        "$actual_path"
    )"

    {
      echo "Item: $label"
      if [ -n "$match" ]; then
        fixture_item_path="$tmp_dir/fixture.json"
        actual_item_path="$tmp_dir/actual.json"
        jq -S . <<<"$fixture_item" >"$fixture_item_path"
        jq -S . <<<"$match" >"$actual_item_path"
        if ! diff -u "$fixture_item_path" "$actual_item_path"; then
          :
        fi
      else
        echo "Missing on page."
      fi
      echo
    } >>"$report_path"
  done

if [ -s "$report_path" ]; then
  echo "Fixture mismatch for $script_name:" >&2
  echo >&2
  cat "$report_path" >&2
  exit 1
fi
