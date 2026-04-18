{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

let
  chromeExe = pkgs.lib.getExe pkgs.google-chrome;
  googleChromeForShell = pkgs.symlinkJoin {
    name = "google-chrome-for-shell";
    paths = [ pkgs.google-chrome ];
    postBuild = ''
      rm "$out/bin/google-chrome-stable"
      cat > "$out/bin/google-chrome-stable" <<'EOF'
#!${pkgs.bash}/bin/bash
set -euo pipefail

profile_dir="''${JSONHUB_CHROME_USER_DATA_DIR:-$PWD/.jsonhub/chrome-profile}"
mkdir -p "$profile_dir"

exec ${chromeExe} \
  --user-data-dir="$profile_dir" \
  --no-first-run \
  --no-default-browser-check \
  "$@"
EOF
      chmod +x "$out/bin/google-chrome-stable"
    '';
  };
in
pkgs.mkShell {
  packages = [
    pkgs.bun
    pkgs.jq
    pkgs.lsof
    googleChromeForShell
  ];

  shellHook = ''
    export JSONHUB_CHROME_USER_DATA_DIR="$PWD/.jsonhub/chrome-profile"
    export JSONHUB_CHROME_CDP_PORT=9222
    export PWTEST_CLI_GLOBAL_CONFIG="$PWD/.jsonhub"
    export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
    export PLAYWRIGHT_BROWSERS_PATH="$PWD/.jsonhub/ms-playwright"

    mkdir -p "$JSONHUB_CHROME_USER_DATA_DIR"
    mkdir -p "$PLAYWRIGHT_BROWSERS_PATH"
    mkdir -p "$PWTEST_CLI_GLOBAL_CONFIG/.playwright"

    cat > "$PWTEST_CLI_GLOBAL_CONFIG/.playwright/cli.config.json" <<EOF
{
  "browser": {
    "browserName": "chromium",
    "userDataDir": "$JSONHUB_CHROME_USER_DATA_DIR",
    "launchOptions": {
      "executablePath": "${chromeExe}",
      "headless": true,
      "args": ["--disable-gpu"]
    },
    "contextOptions": {
      "viewport": null
    }
  }
}
EOF
  '';
}
