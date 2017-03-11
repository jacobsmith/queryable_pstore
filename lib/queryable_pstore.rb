require 'pstore'
require 'ostruct'
require 'securerandom'
require 'csv'
require 'fileutils'

require_relative 'query'
require_relative 'csv_converter'
require_relative 'csv_importer'

class QueryablePStore < PStore
  class << self
    def import_csv(filename, opts = {})
      CSVImporter.new.import_csv(filename, opts)
    end

    def import_csv_from_string(string, opts = {})
      CSVImporter.new.import_csv_from_string(string, opts)
    end

    def queryable_header(header)
      CSVImporter.new.convert_header_to_methodable_name(header)
    end
  end

  extend  Forwardable
  attr_accessor :csv_importer
  def_delegator :@csv_importer, :original_headers
  def_delegator :@csv_importer, :headers_and_type

  def initialize(store_name)
    FileUtils.mkdir_p(File.dirname(store_name)) # create the directory if it doesn't exist where we are saving the file
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
