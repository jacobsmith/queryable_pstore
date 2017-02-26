  class Query
    attr_reader :attribute, :condition, :argument
    TERMINATING_FUNCTIONS = [:pluck]

    def initialize(attribute, condition, argument)
      @attribute = attribute
      @condition = condition
      @argument = argument
    end

    def valid?(records)
      valid = attribute_present?(records) || argument_is_block? || terminating_function?
      raise ArgumentError.new("The attribute `#{@attribute}` is not present in the PStore.") unless valid
      valid
    end

    def attribute_present?(records)
      records.any? { |record| record.keys.include? @attribute }
    end

    def argument_is_block?
      @argument.respond_to?(:call)
    end

    def terminating_function?
      TERMINATING_FUNCTIONS.include?(@condition)
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
