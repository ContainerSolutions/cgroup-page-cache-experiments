{ jre, stdenv, fetchurl, gradle, fetchFromGitHub, makeWrapper, pkgs, mesos }:
with pkgs.callPackage ./stuff.nix { };
let 
  mesos-kafka-jar = stdenv.mkDerivation rec {
    name = "kafka-mesos";
    version= "0.9.5.1";
    src = ./kafka;

    phases = "buildPhase";
    propagatedBuildInputs = [ kafka-starter ];

    buildPhase = ''
      . ${stdenv}/setup
      export GRADLE_USER_HOME=`pwd`
      cp -r $src/* .
      substituteInPlace src/scala/ly/stealth/mesos/kafka/HttpServer.scala --replace ".tgz" ".tar"
      substituteInPlace src/scala/ly/stealth/mesos/kafka/Scheduler.scala --replace "NIX_ENTRY_POINT" "${kafka-starter}/bin/kafka-starter"
#      ${gradle}/bin/gradle build 
      ${gradle}/bin/gradle jar -x test
      mkdir $out
      cp *.jar $out
    '';
  };
in
stdenv.mkDerivation {
  name = "kafka-mesos";

  phases = "installPhase";

  installPhase = ''
    . ${stdenv}/setup
    mkdir -p $out/bin

    for jar in ${mesos-kafka-jar}/*.jar; do
      target=$out/$(basename $jar)
      echo $target
      ln -s $jar $target
    done

    ln -s ${bundled_kafka} $out/${kafka_version}.tar
    echo "(cd $out; ${jre}/bin/java -Djava.library.path=$out:${mesos}/lib -jar $out/kafka-mesos-${mesos-kafka-jar.version}.jar \$@)" > $out/bin/kafka-mesos
    chmod +x $out/bin/kafka-mesos
  '';
}
