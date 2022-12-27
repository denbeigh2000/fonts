{ lib, stdenv, mach-nix }:

let
  inherit (builtins) readFile path;

  python = mach-nix.mkPython {
    requirements = readFile ./requirements.txt;
  };

  p = builtins.trace (builtins.attrNames python) python;

  script = stdenv.mkDerivation {
    pname = "update-fonts";
    version = "0.0.0";

    src = path { path = ./.; name = "update-src"; };
    phases = [ "installPhase" ];
    installPhase = ''
      cp $src/update.py $out
    '';
  };
in
  {
    type = "app";
    program = "${p.python}/bin/python ${script}";
  }
