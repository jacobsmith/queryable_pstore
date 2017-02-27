require 'pstore'
require 'ostruct'
require 'securerandom'
require 'csv'

require_relative 'query'
require_relative 'csv_converter'

class QueryablePStore < PStore
  def self.import_csv(filename, opts = {})
    csv_converters = opts.fetch(:convert, []).map { |conversion| CSVConverter.new(conversion) }

    csv = CSV.read(File.open(filename), headers: true, header_converters: -> (header) { header.downcase.to_sym })

    store = new("#{filename}.pstore")
    store.transaction do
      csv.each do |row|
        store[SecureRandom.uuid] = csv_converters.inject(row.to_h) { |hash, converter| converter.convert(hash) }
      end
    end
    
    store
  end
  
  def initialize(store_name)
    super(store_name)
    @queries = []
  end

  def records
    transaction do
      roots.map { |root| fetch(root) } 
    end
  end

  def method_missing(method, argument = nil, &blk)
    attribute = method.to_s.split("_")[0..-2].join("_").to_sym
    modifier = method.to_s.split("_")[-1].to_sym

    query = Query.new(attribute, modifier, argument || blk) 
    @queries << query if query.valid?(records)
    self
  end

  def results
    answer = @queries.inject(records) { |records, queryable| queryable.filter(records) }
    @queries = []
    answer
  rescue StandardError => e
    # In the event something bad happens, get us back to a good state without any queries hanging around
    @queries = []
    raise e
  end
end
