#!/usr/bin/env bash
set -euo pipefail
. /benchmarks/shared.sh

drop_caches
sleep 5

kafka_root=/opt/kafka
BOOTSTRAP_SERVERS=kafka-slave1:9092,kafka-slave2:9092

function producer_bench {
  local topic=$1
  local record_size_in_bytes=$2
  local throughput_messages_per_sec=$3
  local runtime=$4

  let num_records=runtime*throughput_messages_per_sec
  ($kafka_root/bin/kafka-run-class.sh org.apache.kafka.tools.ProducerPerformance \
    --topic $topic \
    --num-records $num_records \
    --record-size $record_size_in_bytes \
    --throughput $throughput_messages_per_sec \
    --producer-props bootstrap.servers=$BOOTSTRAP_SERVERS) | gawk '{ print strftime("%Y:%m:%d %H:%M:%S,"), $0; fflush(); }'
}

producer_bench "test" 10240 20 55
