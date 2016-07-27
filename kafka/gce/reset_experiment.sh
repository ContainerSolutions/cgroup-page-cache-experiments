echo "First unset the experiment argument, and redeploy the configuration."
echo "This will disable all services / programs used for some experiment"

nixops set-args -d swisscom-kafka-gce --unset experiment
nixops deploy -d swisscom-kafka-gce

echo "Remove zookeeper stuff from the master"
nixops ssh -d swisscom-kafka-gce master-1 rm -rf /data/

for node in slave-1 slave-2 slave-3; do
  echo "Resetting mesos slave $node"
  nixops ssh -d swisscom-kafka-gce $node rm -rf /kafka-data/
  nixops ssh -d swisscom-kafka-gce $node rm -rf /var/lib/mesos
done

nixops ssh -d swisscom-kafka-gce master-1 df -h
for node in slave-1 slave-2 slave-3; do
  nixops ssh -d swisscom-kafka-gce $node df -h
done
