class EventSimulator
  Event = Struct.new(:description, :opts, :block, :happened_at)
  def initialize()
    @events = {}
    @kill_pids = []
  end

  def at(time, description, opts={}, &block)
    @events[time] = Event.new(description, opts, block, nil)
  end

  def start!
    last_time = @events.keys.sort.last

    time = 0
    while time <= last_time
      event = @events[time]

      if event
        p [time, event.description]
        event.happened_at = Time.now
        child = fork do
          event.block.call
          exit
        end
        @kill_pids.push(child)
      else
        p [time, :no_event]
      end

      time += 1
      sleep 1 #TODO
    end

    puts "Done. Killing processes"

    @kill_pids.each do |pid|
      p pid
      system("kill -9 #{pid}")
    end
  end

  def event_log
    output = ""

    @events.each do |time_relative, event|
      output += event.happened_at.strftime("%Y:%m:%d %H:%M:%S") + "," + event.description + "\n"
    end

    output
  end
end
