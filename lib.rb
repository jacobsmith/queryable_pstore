require 'pstore'
require 'ostruct'
require 'pry'

class LMNO < PStore
  class Query
    attr_reader :attribute, :condition, :argument

    def initialize(attribute, condition, argument)
      @attribute = attribute
      @condition = condition
      @argument = argument
    end

    def filter(results)
      if @attribute.empty?
        handle_terminating_function(results)
      else
        results.select do |result|
          conditional(result, @condition, @argument)
        end
      end
    end

    def handle_terminating_function(results)
      case @condition
      when :pluck
        results.map { |r| r[@argument] }
      else
        raise "Unknown Terminating Function: #{@condition}"
      end
    end

    def conditional(row, condition, argument)
      thing_to_check = row[@attribute] # for direct comparison methods

      case condition
      when :gt
        thing_to_check > argument
      when :lt
        thing_to_check < argument
      when :eq
        thing_to_check == argument
      when :between
        argument.include?(thing_to_check) 
      when :ilike
        thing_to_check.downcase.include? argument.downcase
      when :lambda
        argument.call(OpenStruct.new(row)) # lambda takes the whole row
      else
        raise "Unknown Conditional: #{condition}"
      end
    end
  end

  ### LMNO
  attr_reader :store

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

    @queries << Query.new(attribute, modifier, argument || blk)
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

# u = LMNO.new('testing.pstore')
# puts u.test_value_gt(0.0).attributes_lambda { |row| row.name == "Daniela" && row[:test_value] < 10.0 }.results
