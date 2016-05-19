require 'date'

class RPlotter
  attr_reader :events, :metrics

  R_COLORS =  %w{cadetblue chartreuse deeppink2 midnightblue red4}
  DEFAULT_OPTS = { plot_log: false }

  def initialize(title, y_label, event_file, metric_files, opts={})
    p opts
    @title = title
    @y_label = y_label
    @opts = DEFAULT_OPTS.merge(opts)
    raw_events = parse_vals(event_file)

    raw_metrics = {}
    metric_files.map do |name, file|
      raw_metrics[name] = parse_vals(file)
    end

    #normalize time so that we have a t=0
    min_time = [raw_events.keys.min, raw_metrics.values.map { |series| series.keys.min }.min].min
    @events = normalize_times(min_time, raw_events)

    @metrics = Hash[
      raw_metrics.map do |name, values| 
        [name, normalize_times(min_time, values)]
      end
    ]

    @max_time = [@events.keys.max, @metrics.values.map { |series| series.keys.max}.max].max

    @min_value = @metrics.values.map { |series| series.values.min }.min
    @max_value = @metrics.values.map { |series| series.values.max}.max
  end

  def plot!(svg_file_name)
    color = {}
    @metrics.keys.each_with_index do |name, idx|
      color[name] = R_COLORS[idx] || raise("No more colors available")
    end

    IO.popen("R --no-save","w") do |r|
      r.puts(%Q{svg("#{svg_file_name}", width=10, height=5)})
      first = true
      @metrics.each do |name, values|
        r.puts("a_keys = c(" + values.map { |l,r| l.to_s }.join(",") + ")")
        r.puts("a_vals = c(" + values.map { |l,r| r.to_s }.join(",") + ")")
        if @opts[:plot_log]
          r.puts("a_vals = log(a_vals)")
        end

        if first
          method = "plot"
        else
          method = "lines"
        end

        r.puts(%Q{#{method}(a_keys, a_vals, main="#{@title}", type="b",pch=3, xlab="Time (s)", ylab="#{@y_label}", col="#{color[name]}")})

        first = false
      end

      @events.each do |time, name|
        r.puts(%Q{abline(v=#{time}, col="red")})
      end

      r.puts('grid(nx = NULL, ny = NULL, col = "lightgray", lty = "dotted")')
      r.puts(<<-EOF)
        opar <- par(fig=c(0, 1, 0, 1), oma=c(0, 0, 0, 0), 
        mar=c(0, 0, 0, 0), new=TRUE)
        plot(0, 0, type='n', bty='n', xaxt='n', yaxt='n')
        legend("topright", legend=c(#{color.keys.map { |c| %Q{"#{c}"}}.join(",")}), pch=20, col=c(#{color.values.map { |c| %Q{"#{c}"}}.join(",")}), horiz=TRUE, bty='n', cex=0.8)
      EOF
      r.puts("dev.off()")
    end
  end

  private
  def parse_vals(file)
    Hash[
      File.read(file).split("\n").map do |line| 
        time, datum = line.split(",")

        [DateTime.strptime(time, "%Y:%m:%d %H:%M:%S"), datum]
      end
    ]
  end

  def normalize_times(min_time, datums)
    result = {}
    datums.each do |time, value|
      result[((time-min_time) * 24 * 60 * 60).to_i] = value
    end
    result
  end
end
