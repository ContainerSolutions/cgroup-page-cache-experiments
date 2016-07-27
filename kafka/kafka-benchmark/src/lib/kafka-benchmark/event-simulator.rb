class EventSimulator
  Event = Struct.new(:description, :opts, :block, :happened_at)

  class Monitor
    attr_accessor :running
    attr_reader :log

    def initialize(host, command)
      @host = host
      @log = ""
      @stopped = false
      @thread = nil
      @command = command
    end

    def start!
      self.running = true
      @thread = Thread.new do
        Thread.current.abort_on_exception = true
        self.worker_thread 
      end
    end

    def stop!
      @thread.kill
    end

    def worker_thread
      sar = ssh_popen(@host, @command)
      loop do
        begin
          @log += sar.readline
        rescue EOFError
          return
        end
      end
      sar.close
    end
  end

  def initialize(hosts_to_monitor)
    @events = {}
    @kill_pids = []
    @hosts_to_monitor = hosts_to_monitor

    @host_monitors = {}
    @hosts_to_monitor.each do |host|
      @host_monitors["host/#{host}"]  = Monitor.new(host,"LC_TIME='POSIX' sar -B 1")

      #TODO V probably only works for hosted/direct
    end
  end

  def add_host_monitor &block 
    @hosts_to_monitor.each do |host|
      name, monitor = block.call(host)
      @host_monitors[name] = monitor
    end
  end

  def at(time, description, opts={}, &block)
    @events[time] ||= []
    @events[time].push Event.new(description, opts, block, nil)
  end

  def stop_at(time)
    at(time, "Stop experiment") do
      # Stop monitoring
      @host_monitors.each do |name, monitor|
        monitor.stop!
      end
    end
  end

  def start_host_monitors
    @host_monitors.each { |name, monitor| monitor.start! }
  end

  def start!
    start_host_monitors
    last_time = @events.keys.sort.last

    time = 0
    while time <= last_time
      events = @events[time] || []

      events.each do |event|
        puts "#{event.description} at t=#{time}\n"
        event.happened_at = Time.now
        child = fork do
          event.block.call
          exit
        end

        @kill_pids.push(child)
      end

      if events.empty?
        puts ".\n"
      end

      $stdout.flush

      stop_sleeping_at = Time.now.to_f + 1

      loop do
        diff = stop_sleeping_at - Time.now.to_f
        if diff <= 0
          break
        else
          sleep diff
        end
      end

      time += 1
    end

    puts "Done. Killing processes"

    @kill_pids.each do |pid|
      Process.kill("HUP", pid) rescue nil
    end

    @kill_pids.each do |pid|
      Process.kill("TERM", pid) rescue nil
    end
    sleep 1
    @kill_pids.each do |pid|
      Process.kill("KILL", pid) rescue nil
    end
  end

  def event_log
    output = ""

    @events.each do |time_relative, events|
      events.each do |event|
        output += event.happened_at.strftime("%Y:%m:%d %H:%M:%S") + "," + event.description + "\n"
      end
    end

    output
  end

  def save_monitoring(directory)
    @host_monitors.each do |name, monitor|
      file_name = File.join(directory, name)
      FileUtils.mkdir_p File.dirname(file_name)
      File.write(file_name, monitor.log)
    end
  end
end
