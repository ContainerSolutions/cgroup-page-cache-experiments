# We don't care if one of these fail; checked below. handy to not re-provision the machine when running benchmarks.
system("kafka-mesos broker add --api http://master-1:7000 0..2 --heap 8192 --constraints 'hostname=unique' --port 31092")
system("kafka-mesos broker start --api http://master-1:7000 0..2");
system("kafka-mesos topic --api http://master-1:7000 add producer-test --partitions=1 --replicas=3")

output = `kafka-topics.sh --list --zookeeper master-1`.chomp 
if $?.exitstatus != 0 || (output != "producer-test")
  puts "Unexpected!" 
  puts "Too many, or too few topics: #{output}"
  exit 1
else
  puts "OK! Topic exists :)"
end
