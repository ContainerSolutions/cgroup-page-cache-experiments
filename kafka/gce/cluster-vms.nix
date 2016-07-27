with import <nixpkgs/lib>;
let 
  config = import ./config.nix;

  makeGceConfiguration = type: mem: { config, pkgs, lib, ... }: {
    deployment.targetEnv = "gce";
    deployment.gce = {
      # credentials
      project = "swisscom-bigdata";
      serviceAccount = "maarten-kafka@swisscom-bigdata.iam.gserviceaccount.com";
      accessKey = "./key.pem";
 
      # instance properties
      region = "europe-west1-b";
      instanceType = type;
      scheduling.automaticRestart = true;
      scheduling.onHostMaintenance = "MIGRATE";
    };
 
    # Don't enable the firewall in this testing environment.
    networking.firewall.enable = false;
 };

 makeServer = type: prefix: mem: idx: nameValuePair "${prefix}-${toString idx}" (makeGceConfiguration type mem);

 makeMaster =  makeServer "n1-standard-1" "master" config.masterMem;
 makeSlave  =  makeServer "n1-standard-4" "slave"  config.slaveMem;
 makeClient =  makeServer "n1-standard-1" "client" config.clientMem;

 vms = listToAttrs (map makeMaster (range 1 config.nrMasters))
    // listToAttrs (map makeSlave  (range 1 config.nrSlaves))
    // listToAttrs (map makeClient (range 1 config.nrClients));
in
  vms
