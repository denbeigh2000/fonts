{ callPackage
, fetchurl
, p7zip
, stdenvNoCC
, symlinkJoin
}:

let
  inherit (builtins) fromJSON readFile;
  shas = fromJSON (readFile ./shas.json);

  mkFontDerivation = (
    { name, description }:
    stdenvNoCC.mkDerivation {
      name = "${name}-font";
      src = fetchurl { inherit (shas.${name}) url sha256; };
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

  update-tool = callPackage ./update {};
}
