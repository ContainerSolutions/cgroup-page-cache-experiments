# Use the first slave to boostrap the cluster.
$bootstrap_servers ="slave-1:9092"

# Creates topics
require "kafka-benchmark/benchmarks/direct/setup"

# We build up the benchmark event simulator.
# This simulator also gathers statistics from the slaves.
es = EventSimulator.new(KAFKA_SLAVES)
es.add_host_monitor do |host|
   ["kafka/#{host}", EventSimulator::Monitor.new(host,"LC_TIME='POSIX' pidstat -r -p `pgrep -u apache-kafka` 1")]
end

t = 0

KAFKA_SLAVES.each do |slave|
  es.at(t, "kill disk caches at #{slave}") do
      # Sync to disk, and drop all filesystem caches.
      drop_caches_on(slave)
  end
end

t+= 10

[10, 100, 200, 300, 400, 500, 600, 700, 800, 900].each do |throughput|
  # On the kafka clients, start the producer bench test
  KAFKA_CLIENTS.each do |client|
    es.at(t, "start producer bench on #{client} with #{throughput} msgs/s") do
      FileUtils.mkdir_p("#{$report_dir}/producers/")

      File.open("#{$report_dir}/producers/#{client}-#{throughput}.log","w") do |output|
        producer_bench_max_time(output, client, 
                    "producer-test", 
                    60, #seconds
                    100 * 1024, # 100 KB messages
                    throughput)
      end
    end
  end

  t += 60
  es.at(t, "DONE producer bench with #{throughput} msgs/s")  {}
  t += 60
end

t += 60

# Define when the experiment stops
es.stop_at(t);

# Run it!
es.start!

# Store global output
File.write("#{$report_dir}/settings.json", File.read(ENV["BENCH_SETTINGS_FILE"]))
File.write("#{$report_dir}/events.log", es.event_log)
es.save_monitoring("#{$report_dir}/monitoring")
