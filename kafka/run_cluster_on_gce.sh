#!/usr/bin/env bash
set -euo pipefail

JUMP_HOST_IP="146.148.19.33"

eval `ssh-agent` 2> /dev/null > /dev/null
function finish {
  kill $SSH_AGENT_PID
}
trap finish "EXIT"
ssh-add ~/.ssh/google_compute_engine 2> /dev/null

(docker build -t containersol/kafka-benchmark . && docker push containersol/kafka-benchmark) | sed -ue 's/^/\x1b[31mBUILDING IMAGE:\x1b[0m /'

echo "Pulling containers in all machines."
(./ssh -A -t -t $JUMP_HOST_IP sudo docker pull containersol/kafka-benchmark | sed -ue 's/^/\x1b[33mJUMP HOST:\x1b[0m /') &
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-master sudo docker pull containersol/kafka-benchmark  | sed -ue 's/^/\x1b[34mMASTER   :\x1b[0m /') &
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave1 sudo docker pull containersol/kafka-benchmark  | sed -ue 's/^/\x1b[35mSLAVE 1  :\x1b[0m /') &
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave2 sudo docker pull containersol/kafka-benchmark  | sed -ue 's/^/\x1b[36mSLAVE2   :\x1b[0m /') &

wait
echo "DONE"

echo "Killing existing containers"
(./ssh -A -t -t $JUMP_HOST_IP sudo docker rm -f kafka-zk | sed -ue 's/^/\x1b[34mKILL ZK:\x1b[0m /') &
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave1 sudo docker rm -f kafka-b1 | sed -ue 's/^/\x1b[35mKILL SLAVE 1  :\x1b[0m /') &
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave2 sudo docker rm -f kafka-b2 | sed -ue 's/^/\x1b[36mKILL SLAVE 2  :\x1b[0m /') &
wait
echo "DONE"

echo "Start ZK master on master node."
(./ssh -A -t -t $JUMP_HOST_IP sudo docker run --net=host --name kafka-zk --entrypoint=/opt/kafka/bin/zookeeper-server-start.sh containersol/kafka-benchmark /opt/kafka/config/zookeeper.properties | sed -ue 's/^/\x1b[34mZK: \x1b[0m /') &
sleep 2

echo "Start slaves"
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave1 sudo docker run --net=host --name kafka-b1 -e BROKER_ID=1 -e ZK_CONNECT=kafka-testclient:2181 containersol/kafka-benchmark start | sed -ue 's/^/\x1b[35mSLAVE 1  :\x1b[0m /') &
slave1_pid=$!
(./ssh -A -t -t $JUMP_HOST_IP ssh -t -t kafka-slave2 sudo docker run --net=host --name kafka-b2 -e BROKER_ID=2 -e ZK_CONNECT=kafka-testclient:2181 containersol/kafka-benchmark start | sed -ue 's/^/\x1b[35mSLAVE 2  :\x1b[0m /') &
slave2_pid=$!

function kill_slaves {
  pgrep ssh | xargs kill
  kill $slave1_pid $slave2_pid
}
trap kill_slaves "EXIT"

while true; do
sleep 1
done
