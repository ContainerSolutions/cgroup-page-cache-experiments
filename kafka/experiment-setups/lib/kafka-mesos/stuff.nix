{ stdenv, fetchurl, bash, jdk, pkgs }:
rec {
  kafka_version = "kafka_2.11-0.9.0.1";
  bundled_kafka = stdenv.mkDerivation {
    name = "bundled-kafka";
    src = fetchurl {
      url = "https://archive.apache.org/dist/kafka/0.9.0.1/kafka_2.11-0.9.0.1.tgz";
      sha256 = "1klri23fjxbzv7rmi05vcqqfpy7dzi1spn2084y1dxsi1ypfkvc9";
    };

    phases = "unpackPhase";
    unpackPhase = ''
      gunzip -ck $src > $out
    '';
  };

  kafka-starter = stdenv.mkDerivation {
    name = "kafka-starter";
    phases = "createWrapper";

    createWrapper = with pkgs; ''
      mkdir -p $out/bin
      cat > $out/bin/kafka-starter <<EOF
      #! ${bash}/bin/bash
      ${gnutar}/bin/tar -xf ${bundled_kafka}
      exec ${jdk}/bin/java \$@
      EOF
      chmod +x $out/bin/kafka-starter
    '';
  };
}
