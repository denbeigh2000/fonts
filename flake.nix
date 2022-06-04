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
          sha256 = "sha256-4ITyRyc8kVE+tNOSeniu5fm/xo2vebszszCvy+f/t9w=";
          description = "A San Francisco Pro derivation.";
        };

        packages.sf-compact = mkFontDerivation {
          name = "sf-compact-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
          sha256 = "1mmc7ps3zmg8bq391xv9n5v2q7y2lrmyksnvix3h76yhw178hw4m";
          description = "A San Francisco Compact derivation.";
        };

        packages.sf-mono = mkFontDerivation {
          name = "sf-mono-font";
          url = "https://developer.apple.com/design/downloads/SF-Mono.dmg";
          sha256 = "sha256-ZXGWbBH3SqZKRu83dPyDdvgi5Y0beFv1wsiZIOdbDZQ=";
          description = "A San Francisco Mono derivation.";
        };

        packages.sf-arabic = mkFontDerivation {
          name = "sf-arabic-font";
          url = "https://developer.apple.com/design/downloads/SF-Arabic.dmg";
          sha256 = "14lkkbjjnm0pvv8jf32q3zllsay8h6rjl7n62j0qql7dsvxmln59";
          description = "A San Francisco Arabic derivation.";
        };

        packages.ny = mkFontDerivation {
          name = "ny-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
          sha256 = "0ih9bnwfsya0chypwgal7afb6n2wbg3pv8v30idhf951ggmzqkky";
          description = "A New York derivation.";
        };
      });
}
