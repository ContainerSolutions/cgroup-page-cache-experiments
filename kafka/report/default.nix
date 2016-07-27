with import <nixpkgs> {};
with pkgs;
stdenv.mkDerivation rec {
  name = "report";
  phases = "genDoc copyStatic";

  src = ./src;

  genDoc = ''
    mkdir -p $out
    ${pandoc}/bin/pandoc ${src}/index.md -o $out/index.html
  '';

  copyStatic = ''
    cp -r ${src}/static $out/
  '';
}
