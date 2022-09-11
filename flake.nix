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
          sha256 = "sha256-HtJ/KdIVOdYocuzQ8qkzTAm7bMITCq3Snv+Bo9WO9iA=";
          description = "A San Francisco Pro derivation.";
        };

        packages.sf-compact = mkFontDerivation {
          name = "sf-compact-font";
          url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
          sha256 = "sha256-7gRJxuB+DOxS6bzHXFNjNH2X4kmO1MhJN2zK5he2XRU=";
          description = "A San Francisco Compact derivation.";
        };

        packages.sf-mono = mkFontDerivation {
          name = "sf-mono-font";
          url = "https://developer.apple.com/design/downloads/SF-Mono.dmg";
          sha256 = "sha256-ulmhu5kXy+A7//frnD2mzBs6q5Jx8r6KwwaY7gmoYYM=";
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
          sha256 = "sha256-Rr0UpJa7kemczCqNn6b8HNtW6PiWO/Ez1LUh/WNk8S8=";
          description = "A New York derivation.";
        };
      });
}
