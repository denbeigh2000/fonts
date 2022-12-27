{
  description =
    "A flake providing certain un-nixpkg'd fonts.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mach-nix = {
      url = "github:DavHau/mach-nix/3.5.0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        pypi-deps-db.follows = "pypi-deps-db";
      };
    };
    pypi-deps-db = {
      url = "github:DavHau/pypi-deps-db/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (builtins) fromJSON readFile;
        pkgs = import nixpkgs { inherit system; };
        shas = fromJSON readFile ./shas.json;

        update = pkgs.callPackage ./update/default.nix {
          mach-nix = mach-nix.lib.${system};
        };

        mkFontDerivation = (
          { name, description }:
          pkgs.stdenvNoCC.mkDerivation {
            name = "${name}-font";
            src = pkgs.fetchurl { inherit (shas.${name}) url sha256; };
            unpackPhase = ''
              runHook preUnpack

              ${pkgs.p7zip}/bin/7z x -y $src
              ${pkgs.p7zip}/bin/7z x -y "**/*.pkg"
              ${pkgs.p7zip}/bin/7z x -y "Payload~"

              rm -rfv !Library

              runHook postUnpack
            '';
            depsBuildBuild = [ pkgs.p7zip ];
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              cp -rv Library/**/*.otf $out/share/fonts/opentype/ || true

              mkdir -p $out/share/fonts/truetype
              cp -rv Library/**/*.ttf $out/share/fonts/truetype/ || true
            '';
            meta = { inherit description; };
          }
        );
      in
      {
        apps = {
          inherit update;
          default = update;
        };

        packages = {
          default = pkgs.symlinkJoin {
            name = "denbeigh-fonts";
            version = "0.1.0";
            paths = with self.packages.${system}; [ sf-pro sf-compact sf-mono ];
          };

          sf-pro = mkFontDerivation {
            name = "sf-pro";
            description = "A San Francisco Pro derivation.";
          };

          sf-compact = mkFontDerivation {
            name = "sf-compact";
            description = "A San Francisco Compact derivation.";
          };

          sf-mono = mkFontDerivation {
            name = "sf-mono";
            description = "A San Francisco Mono derivation.";
          };

          sf-arabic = mkFontDerivation {
            name = "sf-arabic";
            description = "A San Francisco Arabic derivation.";
          };

          ny = mkFontDerivation {
            name = "ny";
            description = "A New York derivation.";
          };
        };
      });
}
