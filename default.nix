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

        # Older Apple dmgs contain a real .pkg: extract it, then its Payload~
        # (a gzip'd cpio). Newer ones (e.g. the refreshed SF-Pro.dmg) are
        # recursed in full by 7z's dmg handler (dmg -> APFS -> xar -> payload)
        # in the single step above, leaving Payload~ as a bare cpio archive
        # and no .pkg on disk.
        pkg=$(find . -name '*.pkg' | head -n1)
        if [ -n "$pkg" ]; then
          ${p7zip}/bin/7z x -y "$pkg"
          ${p7zip}/bin/7z x -y "Payload~"
        else
          ${p7zip}/bin/7z x -y -tCpio Payload~
        fi

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
