let
  keys = (import ../keys);
  mesos_master_address = servers: with builtins; let
    map_zk = name: name + ":2181";
    master_names = attrNames servers.masters;
    zk_servers = concatStringsSep "," (map map_zk master_names);
    in "zk://${zk_servers}/mesos";
in
{
  master = {servers, idx, ...}: { config, pkgs, lib, ... }: with lib;
  let
    kafka-mesos = pkgs.callPackage ./lib/kafka-mesos {};
  in
  {
    services.zookeeper.dataDir = "/data";
    services.zookeeper.enable  = true;
    services.zookeeper.id = idx;
    services.zookeeper.servers =
      let 
        toLine = n: name: "server.${toString (builtins.sub n 1)}=${name}:2888:3888\n";
      in
        concatImapStrings toLine (attrNames servers.masters);

    environment.systemPackages = with pkgs; [ zookeeper mesos kafka-mesos htop];
    services.mesos.master = {
#      ip = trace node nodes.${name}.config.networking.privateIPv4;
      enable = true;
      quorum = ((length (attrNames servers.masters)) / 2) + 1;
      zk = mesos_master_address servers;
      extraCmdLineOptions = [ "--no-hostname_lookup" ];
    };

    services.marathon = {
      enable = true;
      master = mesos_master_address servers;
      user = "root";
    };

    # TODO: this only works with one master.
    systemd.services.kafka-mesos = {
      wantedBy = ["multi-user.target"];
      after = ["mesos-master.service"];
      serviceConfig = {
        ExecStart =''
          ${pkgs.bash}/bin/bash ${kafka-mesos}/bin/kafka-mesos scheduler \
          --api http://master-1:7000 \
          --master master-1:5050 \
          --storage zk:/kafka-mesos \
          --zk master-1:2181
        '';
#  --user kafkamesos
      };
    };

    users.users.kafkamesos = {
      isNormalUser = false;
      isSystemUser = true;
      uid = 950;
      group = "kafkamesos";
      extraGroups = ["kafkamesos"];
    };

    users.groups.kafkamesos = {
      gid = 950;
    };
  };

  slave  = {servers, idx, ...}: { config, pkgs, lib, node,... }: with lib; 
  let
    updated-mesos = with pkgs; callPackage ./lib/patched-updated-mesos {
      sasl = cyrus_sasl;
      inherit (pythonPackages) python boto setuptools wrapPython;
      pythonProtobuf = pythonPackages.protobuf2_5;
      perf = linuxPackages.perf;
    };
    kafka-mesos = pkgs.callPackage ./lib/kafka-mesos {};
  in
  with pkgs.callPackage ./lib/kafka-mesos/stuff.nix {};
  {
    environment.systemPackages = with pkgs; [ sysstat stress zookeeper htop vim gdb kafka-mesos kafka-starter ];
    users.users.root.openssh.authorizedKeys.keys = [ keys.public ];

    virtualisation.docker.enable = true;

#    systemd.services.mesos-slave.path = [ pkgs.curl pkgs.jdk pkgs.gnutar pkgs.gzip pkgs.bzip2 ];

#    services.mesos.slave = {
#      enable = true;
#      withDocker = true;
#      master = mesos_master_address servers;
#      extraCmdLineOptions = ["--no-switch_user"];
#    };

#    systemd.services.mesos-slave.environment.PATH = "${pkgs.tar}/bin:${pkgs.gzip}/bin:${pkgs.jre}/bin";
    systemd.services.mesos-slave2 = let
      cfg = {
      withDocker = true;
      master = mesos_master_address servers;
      extraCmdLineOptions = ["--no-switch_user"];
      logLevel = "INFO";
      containerizers= [ "mesos" "docker" ];
      ip = "0.0.0.0";
      port = 5051;
      workDir = "/var/lib/mesos/slave";
      };
    in
    {
      description = "Mesos Slave";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-interfaces.target" ];
      environment.MESOS_CONTAINERIZERS = concatStringsSep "," cfg.containerizers;
      serviceConfig = {
        ExecStart = ''
          ${updated-mesos}/bin/mesos-slave \
            --ip=${cfg.ip} \
            --port=${toString cfg.port} \
            --master=${cfg.master} \
            --work_dir=${cfg.workDir} \
            --logging_level=${cfg.logLevel} \
            --docker=${pkgs.docker}/libexec/docker/docker  \
            --no-switch_user
        '';
        PermissionsStartOnly = true;
      };
      preStart = ''
        mkdir -m 0700 -p ${cfg.workDir}
      '';
    };

    users.users.kafkamesos = {
      isNormalUser = false;
      isSystemUser = true;
      uid = 950;
      group = "kafkamesos";
      extraGroups = ["kafkamesos"];
    };

    users.groups.kafkamesos = {
      gid = 950;
    };
  };

  client = {servers, idx, bench-settings}: { config, pkgs, lib, ... }: 
  let 
    kafka-benchmark = pkgs.callPackage ../kafka-benchmark { inherit bench-settings; };
    kafka-mesos = pkgs.callPackage ./lib/kafka-mesos {};
  in
  {
    users.users.root.openssh.authorizedKeys.keys = [ keys.public ];

    environment.systemPackages = with pkgs; [ sysstat zookeeper apacheKafka kafka-benchmark ruby kafka-mesos];
  };
}
