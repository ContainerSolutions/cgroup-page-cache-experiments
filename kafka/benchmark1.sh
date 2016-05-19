#!/usr/bin/env bash
set -e
(docker build -t containersol/kafka-benchmark . && docker push containersol/kafka-benchmark) | sed -ue 's/^/\x1b[31mBUILDING IMAGE:\x1b[0m /'
set -euo pipefail

# assume kafka is started
testclient_ip=146.148.19.33
kafka_slave1=130.211.55.60
kafka_slave2=130.211.73.165
all_hosts="$testclient_ip $kafka_slave1 $kafka_slave2"

# setup ssh agent
eval `ssh-agent` 2> /dev/null > /dev/null
function finish {
  kill $SSH_AGENT_PID
}
trap finish "EXIT"
ssh-add ~/.ssh/google_compute_engine 2> /dev/null

# pull the images
for host in $all_hosts; do
  (ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t $host sudo docker pull containersol/kafka-benchmark 2>&1) | sed -ue "s/^/\\x1b[35mPULLING FROM $host  :\\x1b[0m /" &
done
wait

# start benchmark scripts
mkdir -p output/t1/
echo "Starting benchmark scripts..."
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t $testclient_ip sudo docker run --net=host --privileged containersol/kafka-benchmark bash /benchmarks/1/producer.sh 2>&1 > output/t1/benchmark.log &
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t $kafka_slave1 sudo docker run --net=host --privileged containersol/kafka-benchmark bash /benchmarks/1/kafka-slaves.sh 2>&1 > output/t1/slave1.log &
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -t -t $kafka_slave2 sudo docker run --net=host --privileged containersol/kafka-benchmark bash /benchmarks/1/kafka-slaves.sh 2>&1 > output/t1/slave2.log &

echo "Waiting until benchmark is complete..."

wait
