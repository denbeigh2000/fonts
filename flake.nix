{
  description =
    "A flake providing certain un-nixpkg'd fonts.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      overlay = import ./overlay.nix;
    in
    { overlays.default = overlay; } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        update = pkgs.callPackage ./update/default.nix {};

      in
      {
        apps = {
          inherit update;
          default = update;
        };

        packages = {
          inherit (pkgs.denbeigh.fonts) default sf-pro sf-compact sf-mono sf-arabic ny;
        };
      });
}
