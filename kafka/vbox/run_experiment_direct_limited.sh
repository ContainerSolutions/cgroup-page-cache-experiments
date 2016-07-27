echo "First, install the software required for the direct benchmark"
nixops set-args -d swisscom-kafka-vbox --argstr experiment direct-limited
nixops deploy -d swisscom-kafka-vbox

#echo "Give the services 10 seconds to start up."
#sleep 10

BENCHED_AT=`date "+%Y-%m-%d.%H-%M"`
BENCH_RESULT_DIR=/root/bench-results/direct/$BENCHED_AT
nixops ssh -d swisscom-kafka-vbox client-1 mkdir -p $BENCH_RESULT_DIR
nixops ssh -d swisscom-kafka-vbox client-1 -t -t run-kafka-benchmark $BENCH_RESULT_DIR
echo "DONE"
