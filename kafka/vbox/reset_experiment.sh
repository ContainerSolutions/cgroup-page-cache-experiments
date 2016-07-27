echo "First unset the experiment argument, and redeploy the configuration."
echo "This will disable all services / programs used for some experiment"

nixops set-args -d swisscom-kafka-vbox --unset experiment
nixops deploy -d swisscom-kafka-vbox

echo "Remove zookeeper stuff from the nodes"
set -x
nixops ssh master-1 rm -rf /data/*
nixops ssh slave-1 rm -rf /kafka_data/*
nixops ssh slave-2 rm -rf /kafka_data/*
nixops ssh slave-3 rm -rf /kafka_data/*
