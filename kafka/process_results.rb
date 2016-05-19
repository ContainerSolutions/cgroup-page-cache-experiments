require_relative "graphs"
require "tmpdir"

TIMING_REGEXP = /(?<time>\d+:\d+:\d+ \d+:\d+\:\d+,) \d+ records sent, (?<throughput_msgs>\d+(.\d+?)) records\/sec \((?<throughput_mb_s>\d+.?\d*) MB\/sec\), (?<latency_avg>\d+(.\d+?)) ms avg latency, (?<latency_max>\d+(.\d+?)) max latency./

# Extract EVENTs from all log files.
all_events = []
Dir["output/t1/*"].each do |file|
  event_lines = File.read(file).split("\n") \
                .select { |line| line.start_with?("EVENT") } \
                .map { |line| line.gsub(/EVENT /,"").chomp }
  all_events += event_lines
end
all_events.sort!
File.write("output/t1/events.log", all_events.join("\n"))

year = Time.now.year.to_s
timings = File.read("output/t1/benchmark.log").split("\n") \
.select { |line| line.start_with?(year) }

summary = timings.pop # drop last line that contains the summary.

throughput  = File.open("output/t1/throughput.log","w")
avg_latency = File.open("output/t1/avg_latency.log","w")
max_latency = File.open("output/t1/max_latency.log","w")

timings.each do |timing|
  matches = TIMING_REGEXP.match(timing)
  throughput.puts(matches["time"] + matches["throughput"])
  avg_latency.puts(matches["time"] + matches["latency_avg"])
  max_latency.puts(matches["time"] + matches["latency_max"])
end

throughput.close
avg_latency.close
max_latency.close

RPlotter.new("Experiment 1", 
           "Throughput (msg/sec)", 
           "output/t1/events.log", 
           { 
            "Throughput" => "output/t1/throughput.log", 
           }
).plot!("output/t1/throughput.svg")

RPlotter.new("Experiment 1", 
           "Latency (ms)", 
           "output/t1/events.log", 
           { 
            "avg" => "output/t1/avg_latency.log", 
            "max" => "output/t1/max_latency.log", 
           }
).plot!("output/t1/latency.svg")
File.open("output/t1/report.html", "w") do |w|
  w.puts("<p><img src='throughput.svg'></p>")
  w.puts("<p><img src='latency.svg'></p>")
  w.puts("<p>#{summary}</p>")
end
