{
  lib,
  buildNpmPackage,
  fetchzip,
  importNpmLock,
}:

let
  package = lib.importJSON ./package.json;
in
buildNpmPackage (finalAttrs: {
  pname = package.name;
  inherit (package) version;

  src = fetchzip {
    url = "https://registry.npmjs.org/playwriter/-/playwriter-${package.version}.tgz";
    hash = "sha256-prcO6nKyC2ajm8WuzhD6MTZFoKxYlM+lK8fethQVf/c=";
  };

  npmDeps = importNpmLock {
    inherit package;
    packageLock = lib.importJSON ./package-lock.json;
  };
  npmConfigHook = importNpmLock.npmConfigHook;
  dontNpmBuild = true;

  postPatch = ''
    cp ${./package.json} package.json
    cp ${./package-lock.json} package-lock.json
  '';

  postInstall = ''
    skill_file="$out/share/playwriter-skill/SKILL.md"
    install -Dm644 /dev/null "$skill_file"

    cat > "$skill_file" <<'EOF'
---
name: playwriter
description: Control the user's Chromium session via the packaged Playwriter CLI and extension. Prefer this for JS-heavy sites and logged-in browser workflows instead of fresh-browser automation.
---

EOF

    cat "$out/lib/node_modules/playwriter/dist/prompt.md" >> "$skill_file"
  '';

  passthru = {
    extensionDir = "${finalAttrs.finalPackage}/lib/node_modules/playwriter/dist/extension";
    skillDir = "${finalAttrs.finalPackage}/share/playwriter-skill";
  };

  meta = {
    description = "Playwriter CLI packaged for jsonhub";
    homepage = "https://github.com/remorses/playwriter";
    license = lib.licenses.mit;
    mainProgram = "playwriter";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
