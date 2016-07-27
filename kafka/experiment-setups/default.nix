{ config, experiment, bench-settings }:
with import <nixpkgs/lib>;
let 

 # Create a server definition, parameterized by
 # 1) a prefix (like master)
 # 2) a number.
 # This results in basic machines with names like "master-1"
 makeServer = prefix: fn: servers: idx: nameValuePair "${prefix}-${toString idx}" (fn { inherit bench-settings servers idx; });

 funs = import (./. + "/${experiment}.nix");

 makeMaster = makeServer "master" funs.master;
 makeSlave  = makeServer "slave" funs.slave;
 makeClient = makeServer "client" funs.client;

 servers = fix (self: {
   masters = listToAttrs (map (makeMaster self) (range 1 config.nrMasters));
   slaves  = listToAttrs (map (makeSlave  self) (range 1 config.nrSlaves));
   clients = listToAttrs (map (makeClient self) (range 1 config.nrClients));
 });

 all = servers.masters // servers.slaves // servers.clients ;
in
  all
