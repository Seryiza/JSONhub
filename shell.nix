{ pkgs ? import <nixpkgs> { } }:

let
  playwriter = pkgs.callPackage ./nix/playwriter { };
in
import ./nix/dev-shell.nix {
  inherit pkgs playwriter;
}
