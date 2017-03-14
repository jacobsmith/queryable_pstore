require 'pry'

class CSVImporter
  CURRENT_DIRECTORY = "./".freeze

  attr_reader :original_headers, :headers_and_type

  def import_csv(filename, opts = {})
    csv = CSV.read(File.open(filename), headers: true, header_converters: -> (header) { convert_header_to_methodable_name(header, track_original: true) })
    store = create_pstore(csv, opts, filename)
    store.csv_importer = self

    store
  end

  def import_csv_from_string(string, opts = {})
    csv = CSV.parse(string, headers: true, header_converters: -> (header) { convert_header_to_methodable_name(header, track_original: true) })
    store = create_pstore(csv, opts)
    store.csv_importer = self

    store
  end

  def create_pstore(csv, opts = {}, filename = SecureRandom.uuid)
    conversion_required = opts.fetch(:convert, [])
    if opts.fetch(:convert, nil) == :best_guess
      conversion_required = guess_conversion_types(csv)
    end

    csv_converters = conversion_required.map { |header, desired_format| CSVConverter.new(header => desired_format) }
    file_save_location = opts[:save_to_location] || CURRENT_DIRECTORY

    store = QueryablePStore.new("#{file_save_location}#{filename}.pstore")
    store.transaction do
      csv.each do |row|
        store[SecureRandom.uuid] = csv_converters.inject(row.to_h) { |hash, converter| converter.convert(hash) }
      end
    end

    if opts.fetch(:convert, nil) == :best_guess
      original_headers = @original_headers.clone

      original_headers.each do |original_header|
        @headers_and_type ||= {}
        @headers_and_type[original_header] = symbol_to_class(
          conversion_required[
            convert_header_to_methodable_name(original_header)
          ]
        )
      end
    else
      set_headers_and_type(@original_headers, store)
    end

    store
  end

  def symbol_to_class(symbol)
    case symbol
    when :integer
      Integer
    when :float
      Float
    when :string
      String
    else
      raise "Unknown symbol: #{symbol}"
    end
  end

  def guess_conversion_types(csv)
    headers = csv.headers
    headers_and_type = {}

    csv.each do |row|
      headers.each do |header|
        if row[header].match(/\A(\d)+\z/) && (headers_and_type[header].nil? || headers_and_type[header] == :integer)
          headers_and_type[header] = :integer
        elsif row[header].match(/^\d*\.\d+$/) && (headers_and_type[header].nil? || headers_and_type[header] == :float)
          headers_and_type[header] = :float
        else
          headers_and_type[header] = :string
        end
      end
    end

    headers_and_type
  end

  def convert_header_to_methodable_name(header, track_original: false)
    if track_original
      @original_headers ||= []
      @original_headers << header
    end

    header.downcase.gsub(/[^a-z]/, "_").to_sym
  end

  private

  def set_headers_and_type(headers, store)
    headers_and_type = {}
    store.results.first.each_with_index do |key_value, index|
      value = key_value.last

      original_header = headers[index]
      headers_and_type[original_header] = value.class
    end

    @headers_and_type = headers_and_type
  end
end
