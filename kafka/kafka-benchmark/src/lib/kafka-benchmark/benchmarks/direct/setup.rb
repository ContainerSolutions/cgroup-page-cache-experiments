system("kafka-topics.sh --create --topic producer-test --partitions 1 --replication-factor 3 --zookeeper master-1")

output = `kafka-topics.sh --list --zookeeper master-1`.chomp 
if $?.exitstatus != 0 || (output != "producer-test")
  puts "Unexpected!" 
  puts "Too many, or too few topics: #{output}"
  exit 1
end
