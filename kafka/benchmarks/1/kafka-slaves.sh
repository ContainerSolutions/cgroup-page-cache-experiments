#!/usr/bin/env bash
set -euo pipefail
. /benchmarks/shared.sh

drop_caches
sleep 5

sleep 20

let free_bytes=`free | grep Mem | awk '{print $4}'`

# use 95% of the memory
let use_bytes=$free_bytes*95/100

# spread over 4 stress workers
let bytes_per_worker=$use_bytes/4

event_log "start stress `hostname`"
stress --vm 4 --vm-bytes $bytes_per_worker --timeout 20
event_log "stop stress `hostname`"
