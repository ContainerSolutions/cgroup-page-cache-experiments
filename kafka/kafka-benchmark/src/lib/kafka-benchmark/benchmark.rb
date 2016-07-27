require 'open3'

def producer_bench(output, host, topic, num_records, record_size_in_bytes, throughput_messages_per_sec)
  cmd = [
    "kafka-run-class.sh org.apache.kafka.tools.ProducerPerformance",
    "--topic", topic,
    "--num-records", num_records,
    "--record-size", record_size_in_bytes,
    "--throughput", throughput_messages_per_sec,
    "--producer-props", 
    "bootstrap.servers=#{$bootstrap_servers}",
  ].map(&:to_s).join(" ")

  conn = ssh_popen(host, cmd)
  while !conn.eof?
    line = conn.readline.chomp
    output.print Time.now.strftime("%Y:%m:%d %H:%M:%S,") + line + "\n"
    output.flush
  end

  if $?.exitstatus != 0
    raise("Execution failed! output: #{status}\n#{stdout}\n#{stderr}")
  end
end

def producer_bench_max_time(output, host, topic, test_time, record_size_in_bytes, throughput_messages_per_sec)
  num_records = test_time * throughput_messages_per_sec

  producer_bench(output, host, topic, num_records, record_size_in_bytes, throughput_messages_per_sec)
end
