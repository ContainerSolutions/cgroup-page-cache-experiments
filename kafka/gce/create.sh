# Create the definition in nixops, and do the initial deployment
nixops create -d swisscom-kafka-gce cluster-vms.nix cluster-software.nix
nixops deploy -d swisscom-kafka-gce
