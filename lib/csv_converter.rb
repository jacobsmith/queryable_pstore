class CSVConverter
  def initialize(convert)
    @key = convert.keys.first
    @conversion = convert[@key]
  end

  def convert(hash)
    case @conversion
    when :integer
      hash[@key] = hash[@key].to_i
    when :float
      hash[@key] = hash[@key].to_f
    when :string
      # nop, default
    else
      raise ArgumentError.new("Unknown converter: `#{@conversion}`")
    end

    hash
  end

end
