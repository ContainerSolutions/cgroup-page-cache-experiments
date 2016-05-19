require_relative "ruby_lib/cgroup"
require_relative "ruby_lib/event_simulator"

if Process.uid != 0
  $stderr.puts("Must run as root! This program needs to modify /sys/fs/cgroup!")
  exit 1
end

log_path = Pathname.new("output/test2b")
FileUtils.mkdir_p(log_path)

clear_all_caches
base = CGroup.new("cgrouptest").create!
c1 = base.child("c1").create!
c2 = base.child("c2").create!
c3 = base.child("c3").create!
base.set("memory.limit_in_bytes", "3G")
c1.set("memory.limit_in_bytes", "1G")
c2.set("memory.limit_in_bytes", "1G")
c3.set("memory.limit_in_bytes", "1G")

es = EventSimulator.new

es.at(0, "start A") do
  c1.system("./mmap_pagefault_test inputs/1G-A #{log_path.join("a.log")}")
end

es.at(20, "start B") do
  c2.system("./mmap_pagefault_test inputs/1G-B #{log_path.join("b.log")}")
end

es.at(40, "start C") do
  c3.system("./mmap_pagefault_test inputs/1G-C #{log_path.join("c.log")}")
end

es.at(60, "start C2") do
  c3.system("./mmap_pagefault_test inputs/1G-D #{log_path.join("c2.log")}")
end

es.at(80, "end of tests") do
end

es.start!

File.write(log_path.join("events.log"), es.event_log)

system("ps auxf | grep './[m]map_pagefault_test' | awk -F' ' '{print $2}' | xargs kill -9")

c1.destroy!
c2.destroy!
c3.destroy!
base.destroy!
