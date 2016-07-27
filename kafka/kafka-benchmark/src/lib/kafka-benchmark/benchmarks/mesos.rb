# Use the first slave to boostrap the cluster.
$bootstrap_servers ="slave-1:31092"

# Creates topics
require "kafka-benchmark/benchmarks/mesos/setup"

# We build up the benchmark event simulator.
# This simulator also gathers statistics from the slaves.
es = EventSimulator.new(KAFKA_SLAVES)
es.add_host_monitor do |host|
  ["kafka/#{host}", EventSimulator::Monitor.new(host,"LC_TIME='POSIX' pidstat -r -p `ps x | grep ly.stealth.mesos.kafka.Executor | grep jar | awk -F' ' '{ print $1 }'` 1")]
end

t = 0

KAFKA_SLAVES.each do |slave|
  es.at(t, "kill disk caches at #{slave}") do
      # Sync to disk, and drop all filesystem caches.
      drop_caches_on(slave)
  end
end


t+= 10

# On the kafka clients, start the producer bench test
KAFKA_CLIENTS.each do |client|
  es.at(t, "start producer bench on #{client}") do
    FileUtils.mkdir_p("#{$report_dir}/producers/")

    File.open("#{$report_dir}/producers/#{client}.log","w") do |output|
      producer_bench_max_time(output, client, 
                  "producer-test", 
                  180+60+180,
                  $config.producer_test_record_size_in_bytes, 
                  $config.producer_test_throughput_msgs_per_s)
    end
  end
end

t += 180

# Use 98% of available memory for memory stress testing
KAFKA_SLAVES.each do |slave|
  es.at(t, "start stress #{slave} for 60s") do
    free_bytes = ssh_capture(slave, "free | grep Mem | awk '{print $4}'").ok_stdout!.chomp.to_i
    use_bytes = (free_bytes.to_f * 0.98).to_i
    vm_threads = 4
    bytes_per_thread = use_bytes / 4
    cmd = "stress --timeout 60s --vm #{vm_threads} --vm-bytes #{bytes_per_thread} -d #{vm_threads} --hdd-bytes 10G"
    ssh_capture(slave, cmd).ok_stdout!
  end
end

t += 60

KAFKA_SLAVES.each do |slave|
  es.at(t, "stopped stressing #{slave}") {}
end

# 180 seconds to relax, 10 seconds to clean up
t += 180

# Define when the experiment stops
es.stop_at(t);

# Run it!
es.start!

# Store global output
File.write("#{$report_dir}/settings.json", File.read(ENV["BENCH_SETTINGS_FILE"]))
File.write("#{$report_dir}/events.log", es.event_log)
es.save_monitoring("#{$report_dir}/monitoring")
