{ fetchurl
, p7zip
, stdenvNoCC
, symlinkJoin
}:

let
  inherit (stdenvNoCC.platform) system;

  mkFontDerivation = (
    { name, url, sha256, description }:
    stdenvNoCC.mkDerivation {
      inherit name;
      src = fetchurl { inherit url sha256; };
      unpackPhase = ''
        runHook preUnpack

        ${p7zip}/bin/7z x -y $src
        ${p7zip}/bin/7z x -y "**/*.pkg"
        ${p7zip}/bin/7z x -y "Payload~"

        rm -rfv !Library

        runHook postUnpack
      '';
      depsBuildBuild = [ p7zip ];
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
rec {
  default = symlinkJoin {
    name = "denbeigh-fonts";
    version = "0.1.0";
    paths = [ sf-pro sf-compact sf-mono ];
  };

  sf-pro = mkFontDerivation {
    name = "sf-pro-font";
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sha256 = "0z3cbaq9dk8dagjh3wy20cl2j48lqdn9q67lbqmrrkckiahr1xw3";
    description = "A San Francisco Pro derivation.";
  };

  sf-compact = mkFontDerivation {
    name = "sf-compact-font";
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    sha256 = "04sq98pldn9q1a1npl6b64karc2228zgjj4xvi6icjzvn5viqrfj";
    description = "A San Francisco Compact derivation.";
  };

  sf-mono = mkFontDerivation {
    name = "sf-mono-font";
    url = "https://developer.apple.com/design/downloads/SF-Mono.dmg";
    sha256 = "0fdcras7y7cvym6ahhgn7ih3yfkkhr9s6h5b6wcaw5svrmi6vbxb";
    description = "A San Francisco Mono derivation.";
  };

  sf-arabic = mkFontDerivation {
    name = "sf-arabic-font";
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Arabic.dmg";
    sha256 = "0habrwbdsffkg2dnnawna8w93psc2n383hyzvsxn3a5n7ai63mp2";
    description = "A San Francisco Arabic derivation.";
  };

  ny = mkFontDerivation {
    name = "ny-font";
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    sha256 = "1q0b741qiwv5305sm3scd9z2m91gdyaqzr4bd2z54rvy734j1q0y";
    description = "A New York derivation.";
  };
}
