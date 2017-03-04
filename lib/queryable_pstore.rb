require 'pstore'
require 'ostruct'
require 'securerandom'
require 'csv'

require_relative 'query'
require_relative 'csv_converter'
require_relative 'csv_importer'

class QueryablePStore < PStore
  extend SingleForwardable
  def_delegator :CSVImporter, :import_csv

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
