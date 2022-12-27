{ lib, stdenv, git, makeWrapper, openssh, python310 }:

let
  inherit (builtins) readFile path;

  python = python310.withPackages (p: with p; [
    requests
    types-requests
  ]);
in
stdenv.mkDerivation {
  pname = "update-fonts";
  version = "0.0.0";

  src = path { path = ./.; name = "update-src"; };
  nativeBuildInputs = [ python makeWrapper ];

  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/update.py $out/bin/update
    chmod +x $out/bin/update

    patchShebangs $out/bin
  '';

  postFixup = ''
    wrapProgram $out/bin/update --prefix PATH : ${lib.makeBinPath [ git openssh ]}
  '';
}
