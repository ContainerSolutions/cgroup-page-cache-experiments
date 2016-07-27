class Config < BasicObject
  def initialize(values)
    @values = values
  end

  def method_missing(name, *args, &block)
    str_name = name.to_s

    if @values.has_key?(str_name)
      @values[str_name]
    else
      super(name, *args, &block)
    end
  end
end
