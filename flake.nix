{
  description = "jsonhub development shell with Chromium for browser-based script testing";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          playwriter = pkgs.callPackage ./nix/playwriter { };
        in
        {
          inherit playwriter;
          default = playwriter;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
          playwriter = self.packages.${system}.playwriter;
        in
        {
          default = import ./nix/dev-shell.nix {
            inherit pkgs playwriter;
          };
        }
      );
    };
}
