{
  description =
    "A flake providing certain un-nixpkg'd fonts.";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        mkFontDerivation = (
          { name, url, sha256, description }:
          pkgs.stdenvNoCC.mkDerivation {
            inherit name;
            src = pkgs.fetchurl { inherit url sha256; };
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
        defaultPackage = pkgs.symlinkJoin {
          name = "denbeigh-fonts";
          version = "0.1.0";
          paths = with self.packages.${system}; [ sf-pro sf-compact sf-mono ];
        };

        packages.sf-pro = mkFontDerivation {
          name = "sf-pro-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
          sha256 = "sha256-g/eQoYqTzZwrXvQYnGzDFBEpKAPC8wHlUw3NlrBabHw=";
          description = "A San Francisco Pro derivation.";
        };

        packages.sf-compact = mkFontDerivation {
          name = "sf-compact-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
          sha256 = "sha256-0mUcd7H7SxZN3J1I+T4SQrCsJjHL0GuDCjjZRi9KWBM=";
          description = "A San Francisco Compact derivation.";
        };

        packages.sf-mono = mkFontDerivation {
          name = "sf-mono-font";
          url = "https://developer.apple.com/design/downloads/SF-Mono.dmg";
          sha256 = "sha256-q69tYs1bF64YN6tAo1OGczo/YDz2QahM9Zsdf7TKrDk=";
          description = "A San Francisco Mono derivation.";
        };

        packages.sf-arabic = mkFontDerivation {
          name = "sf-arabic-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg";
          sha256 = "sha256-4tZhojq2qGG73t/DgYYVTN+ROFKWK2ubeNM53RbPS0E=";
          description = "A San Francisco Arabic derivation.";
        };

        packages.ny = mkFontDerivation {
          name = "ny-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
          sha256 = "sha256-HuAgyTh+Z1K+aIvkj5VvL6QqfmpMj6oLGGXziAM5C+A=";
          description = "A New York derivation.";
        };
      });
}
