require 'pstore'
require 'pry'

class Urology < PStore
  class Queryable
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
          conditional(result[@attribute], @condition, @argument)
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

    def conditional(thing_to_check, condition, argument)
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
      else
        raise "Unknown Conditional: #{condition}"
      end
    end
  end

  ### Urology
  attr_reader :store

  def initialize(store_name)
    super(store_name)
    @queryables = []
  end

  def records
    transaction do
      roots.map { |root| fetch(root) } 
    end
  end

  def method_missing(method, argument)
    attribute = method.to_s.split("_")[0..-2].join("_").to_sym
    modifier = method.to_s.split("_")[-1].to_sym

    @queryables << Queryable.new(attribute, modifier, argument)
    self
  end

  def results
    answer = @queryables.inject(records) { |records, queryable| queryable.filter(records) }
    @queryables = []
    answer
  rescue StandardError => e
    # In the event something bad happens, get us back to a good state without any queryables hanging around
    @queryables = []
    raise e
  end
end

# u = Urology.new('sidekiq.pstore')
# u.time_to_complete_gt(0.5).results
