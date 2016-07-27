let
  keys = (import ../keys);
in
{
  master = {servers, idx, ...}: { config, pkgs, lib, ... }: with lib; {
    services.zookeeper.dataDir = "/data";
    services.zookeeper.enable  = true;
    services.zookeeper.id = idx;
    services.zookeeper.servers =
      let 
        toLine = n: name: "server.${toString (builtins.sub n 1)}=${name}:2888:3888\n";
      in
        concatImapStrings toLine (attrNames servers.masters);

    environment.systemPackages = with pkgs; [ zookeeper ];
  };

  slave  = {bench-settings, servers, idx, ...}: { config, pkgs, lib, node,... }: with lib; {
    systemd.units."limited-stress.slice".text = ''
      [Unit]
      Description=Limit stress test impact
      Before=slices.target

      [Slice]
      MemoryAccounting=true
      MemoryLimit=${toString bench-settings.limited_stress_slice_size_limit_in_mb};
    '';
    services.apache-kafka.enable = true;
    services.apache-kafka.brokerId  = idx;
    services.apache-kafka.hostname = "slave-${toString idx}";
    services.apache-kafka.zookeeper = concatStringsSep "," (map (name: name + ":2181") (attrNames servers.masters));
    services.apache-kafka.logDirs = [ "/kafka-data" ];
    services.apache-kafka.jvmOptions = [ 
      "-server" 
      "-Xmx8G"
      "-Xms8G"
      "-XX:+UseCompressedOops"
      "-XX:+UseParNewGC"
      "-XX:+UseConcMarkSweepGC"
      "-XX:+CMSClassUnloadingEnabled"
      "-XX:+CMSScavengeBeforeRemark"
      "-XX:+DisableExplicitGC"
      "-Djava.awt.headless=true"
      "-Djava.net.preferIPv4Stack=true"
    ];
    environment.systemPackages = with pkgs; [ sysstat stress zookeeper htop ];
    users.users.root.openssh.authorizedKeys.keys = [ keys.public ];
  };

  client = {servers, idx, bench-settings}: { config, pkgs, lib, ... }: 
  let 
    kafka-benchmark = pkgs.callPackage ../kafka-benchmark { inherit bench-settings; };
  in
  {
    users.users.root.openssh.authorizedKeys.keys = [ keys.public ];

    environment.systemPackages = with pkgs; [ sysstat zookeeper apacheKafka kafka-benchmark ruby ];
  };
}
