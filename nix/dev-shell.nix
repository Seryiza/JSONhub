{ pkgs, playwriter }:

let
  extensionDirs = [ playwriter.passthru.extensionDir ];
  extensionFlags = pkgs.lib.concatStringsSep "," extensionDirs;

  installPlaywriterSkill = pkgs.writeShellApplication {
    name = "jsonhub-install-playwriter-skill";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      codexHome="''${CODEX_HOME:-$HOME/.codex}"
      skillDir="$codexHome/skills/playwriter"

      mkdir -p "$skillDir"
      install -m 0644 "${playwriter.passthru.skillDir}/SKILL.md" "$skillDir/SKILL.md"

      printf 'Installed Playwriter skill to %s\n' "$skillDir"
    '';
  };

  jsonhubChrome = pkgs.writeShellApplication {
    name = "jsonhub-chrome";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.chromium
    ];
    text = ''
      profileDir="$PWD/.jsonhub/chromium-profile"
      mkdir -p "$profileDir"

      exec "${pkgs.chromium}/bin/chromium" \
        --user-data-dir="$profileDir" \
        --disable-extensions-except="${extensionFlags}" \
        --load-extension="${extensionFlags}" \
        --no-first-run \
        --no-default-browser-check \
        "$@"
    '';
  };
in
pkgs.mkShell {
  packages = [
    playwriter
    pkgs.chromium
    pkgs.lsof
    installPlaywriterSkill
    jsonhubChrome
  ];

  shellHook = ''
    export JSONHUB_CHROME_BIN="${pkgs.chromium}/bin/chromium"
    export CHROME_BIN="$JSONHUB_CHROME_BIN"
    export PLAYWRITER_BIN="${playwriter}/bin/playwriter"
    export PLAYWRITER_EXTENSION_DIR="${playwriter.passthru.extensionDir}"
    export JSONHUB_CHROME_EXTENSION_DIRS="${extensionFlags}"
    export PLAYWRITER_SKILL_DIR="${playwriter.passthru.skillDir}"
    export JSONHUB_CHROME_USER_DATA_DIR="$PWD/.jsonhub/chromium-profile"
    mkdir -p "$JSONHUB_CHROME_USER_DATA_DIR"
  '';
}
