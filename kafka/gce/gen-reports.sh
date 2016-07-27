#! /bin/sh
nixops mount -d swisscom-kafka-gce client-1:/root/bench-results/ bench-results
set -x
nix-build generate_report.nix -A report
fusermount -u bench-results
