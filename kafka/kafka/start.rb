#!/usr/bin/env ruby

DEFAULTS = {
  "BROKER_ID" => "0",
  "NUM_NETWORK_THREADS" => "3",
  "NUM_IO_THREADS" => "8",
  "SOCKET_SEND_BUFFER_BYTES" => "102400",
  "SOCKET_RECEIVE_BUFFER_BYTES" => "102400",
  "SOCKET_REQUEST_MAX_BYTES" => "104857600",
  "LOG_DIRS" => "/tmp/kafka-logs",
  "NUM_PARTITIONS" => "1",
  "ZK_CONNECT" => "localhost:2181",
  "ZK_TIMEOUT_MS" => "6000",
  "ZK_TIMEOUT_MS" => "6000",
  "KAFKA_PORT" => "9092",
}

if ENV["BROKER_ID"].nil?
  $stderr.puts("BROKER_ID env var must be set!")
  exit 1
end

# Load non defaults via env vars
config = DEFAULTS.dup
DEFAULTS.keys.each do |key|
  if ENV.has_key?(key)
    config[key] = ENV[key]
  end
end

File.open("/opt/kafka/server.conf", "w") do |f|
  f.puts("broker.id = #{config["BROKER_ID"]}")
  f.puts("num.network.threads=#{config["NUM_NETWORK_THREADS"]}")
  f.puts("num.io.threads=#{config["NUM_IO_THREADS"]}")
  f.puts("socket.send.buffer.bytes=#{config["SOCKET_SEND_BUFFER_BYTES"]}")
  f.puts("socket.receive.buffer.bytes=#{config["SOCKET_RECEIVE_BUFFER_BYTES"]}")
  f.puts("socket.request.max.bytes=#{config["SOCKET_REQUEST_MAX_BYTES"]}")
  f.puts("log.dirs=#{config["LOG_DIRS"]}")
  f.puts("num.partitions=#{config["NUM_PARTITIONS"]}")
  f.puts("zookeeper.connect=#{config["ZK_CONNECT"]}")
  f.puts("zookeeper.connection.timeout.ms=#{config["ZK_TIMEOUT_MS"]}")

  f.puts("listeners=PLAINTEXT://:#{config["KAFKA_PORT"]}")
  f.puts("num.recovery.threads.per.data.dir=1")
  f.puts("log.retention.hours=168")
  f.puts("log.segment.bytes=1073741824")
  f.puts("log.retention.check.interval.ms=300000")
  f.puts("delete.topic.enable=true")

  if ENV.has_key?("KAFKA_HOSTNAME")
    f.puts(%Q{host.name=#{ENV["KAFKA_HOSTNAME"]}})
    f.puts(%Q{advertised.host.name=#{ENV["KAFKA_HOSTNAME"]}})
  end
end

exec("/opt/kafka/bin/kafka-server-start.sh /opt/kafka/server.conf")
