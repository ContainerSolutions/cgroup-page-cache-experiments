BENCH_NAME=mesos
echo "First, install the software required for the direct benchmark"
nixops set-args -d swisscom-kafka-gce --argstr experiment mesos
nixops deploy -d swisscom-kafka-gce

echo "Give the services 45 seconds to start up."
sleep 45

BENCHED_AT=`date "+%Y-%m-%d.%H-%M"`
BENCH_RESULT_DIR=/root/bench-results/$BENCH_NAME/$BENCHED_AT
nixops ssh -d swisscom-kafka-gce client-1 mkdir -p $BENCH_RESULT_DIR
nixops ssh -d swisscom-kafka-gce client-1 -t -t run-kafka-benchmark $BENCH_NAME $BENCH_RESULT_DIR
echo "DONE"
