{ bench-settings }:
with import <nixpkgs> {};
with pkgs;
let 
k = (callPackage ./default.nix { inherit bench-settings; });
in
{
  kafka-benchmark = k;
}
