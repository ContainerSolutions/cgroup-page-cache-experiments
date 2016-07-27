require 'date'
require 'tempfile'
require 'open3'

class RPlotter
  attr_reader :events, :metrics

  R_SYMBOLS = (19..25).to_a
  R_COLORS =  %w{cadetblue chartreuse deeppink2 midnightblue red4}
  R_SERIES = R_SYMBOLS.product(R_COLORS)

  DEFAULT_OPTS = { plot_log: false, type: "b", min_max: 1 }

  # raw_metrics = { name => { DateTime => metric value } }
  def initialize(title, y_label, event_file, raw_metrics, opts={})
    @title = title
    @y_label = y_label
    @opts = DEFAULT_OPTS.merge(opts)
    raw_events = parse_vals(File.read(event_file))

    #normalize time so that we have a t=0
    min_time = [raw_events.keys.min, raw_metrics.values.map { |series| series.keys.min }.min].min
    @events = normalize_times(min_time, raw_events)

    @metrics = Hash[
      raw_metrics.map do |name, values| 
        [name, normalize_times(min_time, values)]
      end
    ]

    @max_time = [@events.keys.max, @metrics.values.map { |series| series.keys.max}.max].max
    if @max_time > 2000
      raise "Bad times #{@max_time}"
    end

    @min_value = @metrics.values.map { |series| series.values.min }.min
    @max_value = @metrics.values.map { |series| series.values.max }.max
  end

  def plot!(png_file_name)
    colors = {}
    symbols = {}
    @metrics.keys.each_with_index do |name, idx|
      symbol, color = (R_SERIES[idx] || raise("No more colors available"))
      colors[name] = color
      symbols[name] = symbol
    end

    max_value = [@max_value, @opts[:min_max]].max

    r = Tempfile.new("rscript")
    r.puts(%Q{png("#{png_file_name}", width=1000, height=500, unit="px", pointsize=12)})
    first = true
    @metrics.each do |name, values|
      if values.any? { |l, r| !r.kind_of?(BigDecimal)}
        raise "Only bigdecimals are accepted!"
      end
      r.puts("a_keys = c(" + values.map { |l,r| l.to_s }.join(",") + ")")
      r.puts("a_vals = c(" + values.map { |l,r| r.to_s("f") }.join(",") + ")")
      if @opts[:plot_log]
        r.puts("a_vals = log(a_vals)")
      end

      if first
        method = "plot"
      else
        method = "lines"
      end

      r.puts(%Q{#{method}(a_keys, a_vals, main="#{@title}", xlim=c(0,#{@max_time}), ylim=c(0, #{max_value}), type="#{@opts[:type]}", xlab="Time (s)", ylab="#{@y_label}", col="#{colors[name]}", pch=#{symbols[name]})})

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
      legend("topright", legend=c(#{colors.keys.map { |c| %Q{"#{c}"}}.join(",")}), pch=c(#{symbols.values.map(&:to_s).join(",")}), col=c(#{colors.values.map { |c| %Q{"#{c}"}}.join(",")}), horiz=TRUE, bty='n', cex=0.8)
    EOF
    r.puts("dev.off()")
    r.flush

    output, status = Open3.capture2e("Rscript #{r.path}")

    if status.exitstatus != 0
      raise("Failed to generate graph!: #{output}")
    else
    end
  end

  private
  def parse_vals(content)
    Hash[
      content.split("\n").map do |line| 
        time, datum = line.split(",")

        [DateTime.strptime(time, "%Y:%m:%d %H:%M:%S"), BigDecimal.new(datum)]
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
