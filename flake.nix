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
    {
      overlays.default = overlay;
      nixosModules.update-tool = (import ./update/module.nix);
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        update = {
          type = "app";
          program = "${pkgs.denbeigh.fonts.update-tool}/bin/update";
        };
      in
      {
        apps = {
          inherit update;
          default = update;
        };

        packages = {
          inherit (pkgs.denbeigh.fonts) default sf-pro sf-compact sf-mono sf-arabic ny update-tool;
        };
      });
}
