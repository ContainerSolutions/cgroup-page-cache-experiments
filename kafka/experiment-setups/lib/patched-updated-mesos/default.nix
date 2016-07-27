{ stdenv, lib, makeWrapper, fetchurl, curl, sasl, openssh, autoconf
, automake115x, libtool, unzip, gnutar, jdk, maven, python, wrapPython
, setuptools, boto, pythonProtobuf, apr, subversion, gzip, systemd
, leveldb, glog, perf, utillinux, libnl, iproute, openssl, libevent
, bash, replaceDependency, callPackage, pythonPackages, linuxPackages,
  coreutils,
}:
replaceDependency {
   drv = callPackage ../updated-mesos {
      inherit sasl;
      inherit (pythonPackages) python boto setuptools wrapPython;
      pythonProtobuf = pythonPackages.protobuf2_5;
      perf = linuxPackages.perf;
   };

   oldDependency = gnutar;
   newDependency = stdenv.mkDerivation {
     name = "gnutar-1.29";
     buildInputs = [ makeWrapper ];
     phases = "installPhase";
     installPhase = ''
      mkdir -p $out/bin
      echo '#!${bash}/bin/bash' > $out/bin/tar
      echo 'LOG_FILE=/tmp/mesos-tar-log-`${coreutils}/bin/date +%s`' >> $out/bin/tar
      echo 'echo "Arguments: $@" > $LOG_FILE' >> $out/bin/tar
      echo 'echo Arg1: $1 >> $LOG_FILE ' >> $out/bin/tar
      echo 'echo Arg2: $2 >> $LOG_FILE ' >> $out/bin/tar
      echo 'echo Arg3: $3 >> $LOG_FILE ' >> $out/bin/tar
      echo 'echo Arg4: $4 >> $LOG_FILE ' >> $out/bin/tar
      echo 'echo starting tar >> $LOG_FILE' >> $out/bin/tar
      echo '(${gnutar}/bin/tar $@) 2>&1 >> $LOG_FILE' >> $out/bin/tar

      chmod +x $out/bin/tar
    '';
   };
}
