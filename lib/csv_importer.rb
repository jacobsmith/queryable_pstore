class CSVImporter
  CURRENT_DIRECTORY = "./".freeze

  attr_reader :original_headers, :headers_and_type

  def import_csv(filename, opts = {})
    csv = CSV.read(File.open(filename), headers: true, header_converters: -> (header) { convert_header_to_methodable_name(header) })
    store = create_pstore(csv, opts, filename)
    store.csv_importer = self
    set_headers_and_type(@original_headers, store)

    store
  end

  def import_csv_from_string(string, opts = {})
    csv = CSV.parse(string, headers: true, header_converters: -> (header) { convert_header_to_methodable_name(header) })
    store = create_pstore(csv, opts)
    store.csv_importer = self
    set_headers_and_type(@original_headers, store)

    store
  end

  def create_pstore(csv, opts = {}, filename = SecureRandom.uuid)
    csv_converters = opts.fetch(:convert, []).map { |conversion| CSVConverter.new(conversion) }
    file_save_location = opts[:save_to_location] || CURRENT_DIRECTORY

    store = QueryablePStore.new("#{file_save_location}#{filename}.pstore")
    store.transaction do
      csv.each do |row|
        store[SecureRandom.uuid] = csv_converters.inject(row.to_h) { |hash, converter| converter.convert(hash) }
      end
    end

    store
  end

  def convert_header_to_methodable_name(header)
    @original_headers ||= []
    @original_headers << header

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
