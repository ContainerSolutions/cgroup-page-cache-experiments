{ pkgs, stdenv, lib, bundler, R, ruby, makeWrapper, bench-settings }:
let
  key_file = pkgs.writeText "kafka-bench-ssh-key" ((import ../keys).private);
  settings_file = pkgs.writeText "bench-settings" (builtins.toJSON bench-settings);
in
stdenv.mkDerivation {
  name = "kafka-benchmark";
  src = ./src;
  builtInputs = [ makeWrapper ];
  propagatedBuildInputs = [ ruby R ];

  buildPhase = ''
    . "${makeWrapper}/nix-support/setup-hook"
    mkdir -p $out{,lib,bin}
    cp -r $src/lib $out/lib
    for file in run-kafka-benchmark create-kafka-report; do
      makeWrapper $src/bin/$file $out/bin/$file \
      --set "SSH_PRIVATE_KEY_FILE" ${key_file} \
      --set "BENCH_SETTINGS_FILE" ${settings_file} \
      --set "RUBYLIB" $out/lib
    done
  '';

  installPhase = "true";
}
