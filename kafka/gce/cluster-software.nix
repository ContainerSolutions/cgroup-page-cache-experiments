{ experiment ? "none" }:
let
  config = import ./config.nix;
  bench-settings = import ./bench-settings.nix;
  softwareSetup = import ../experiment-setups { inherit config experiment bench-settings; };
in
  softwareSetup
