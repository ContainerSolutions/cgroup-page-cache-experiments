with import <nixpkgs/lib>;
let 
 config = import ./config.nix;

 makeVboxConfiguration = mem : { config, pkgs, lib, ... }: {
   deployment.targetEnv = "virtualbox";
   deployment.virtualbox.headless = true;
   deployment.virtualbox.memorySize = mem;

   # Don't enable the firewall in this testing environment.
   networking.firewall.enable = false;
 };

 makeServer = prefix: mem: idx: nameValuePair "${prefix}-${toString idx}" (makeVboxConfiguration mem);

 makeMaster =  makeServer "master" config.masterMem;
 makeSlave  =  makeServer "slave"  config.slaveMem;
 makeClient =  makeServer "client" config.clientMem;

 vms = listToAttrs (map makeMaster (range 1 config.nrMasters))
    // listToAttrs (map makeSlave  (range 1 config.nrSlaves))
    // listToAttrs (map makeClient (range 1 config.nrClients));
in
  vms
