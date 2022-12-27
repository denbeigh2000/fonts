{ lib, stdenv, python311 }:

let
  inherit (builtins) readFile path;

  python = python311.withPackages (p: with p; [
    requests
    types-requests
  ]);

  script = stdenv.mkDerivation {
    pname = "update-fonts";
    version = "0.0.0";

    buildInputs = [ python ];
    doUnpack = false;

    src = path { path = ./.; name = "update-src"; };
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      cp $src/update.py $out/bin/update
      chmod +x $out/bin/update
    '';
  };
in
  {
    type = "app";
    program = "${script}/bin/update";
  }
