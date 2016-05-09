require_relative "ruby_lib/cgroup"
require_relative "ruby_lib/event_simulator"

if Process.uid != 0
  $stderr.puts("Must run as root! This program needs to modify /sys/fs/cgroup!")
  exit 1
end

log_path = Pathname.new("output/test2")
FileUtils.mkdir_p(log_path)

clear_all_caches
base = CGroup.new("cgrouptest").create!
c1 = base.child("c1").create!
c2 = base.child("c2").create!
base.set("memory.limit_in_bytes", "1000M")
c1.set("memory.limit_in_bytes", "500M")
c2.set("memory.limit_in_bytes", "500M")

es = EventSimulator.new

es.at(0, "start A") do
  c1.system("./mmap_pagefault_test inputs/50mb-A #{log_path.join("a.log")}")
end

es.at(20, "start B") do
  c1.system("./mmap_pagefault_test inputs/50mb-B #{log_path.join("b.log")}")
end

es.at(40, "end of tests") do
end

es.start!

File.write(log_path.join("events.log"), es.event_log)

system("ps auxf | grep './[m]map_pagefault_test' | awk -F' ' '{print $2}' | xargs kill -9")

c1.destroy!
c2.destroy!
base.destroy!
