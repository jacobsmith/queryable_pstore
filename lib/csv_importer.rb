class CSVImporter
  def self.import_csv(filename, opts = {})
    csv_converters = opts.fetch(:convert, []).map { |conversion| CSVConverter.new(conversion) }

    csv = CSV.read(File.open(filename), headers: true, header_converters: -> (header) { convert_header_to_methodable_name(header) })

    store = QueryablePStore.new("#{filename}.pstore")
    store.transaction do
      csv.each do |row|
        store[SecureRandom.uuid] = csv_converters.inject(row.to_h) { |hash, converter| converter.convert(hash) }
      end
    end

    store
  end

  def self.convert_header_to_methodable_name(header)
    header.downcase.gsub(/[^a-z]/, "_").to_sym
  end
end
