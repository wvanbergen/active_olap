module ActiveRecord::Olap

  class Aggregate
  
    attr_reader :klass
    attr_reader :label
      
    attr_reader :function
    attr_reader :distinct
    attr_reader :expression

    attr_reader :joins
    attr_reader :info

    def self.all_from_olap_query_call(klass, aggregates_given)
      aggregates_given = [aggregates_given] unless aggregates_given.kind_of?(Array)
      
      return aggregates_given.map do |aggregate_definition|
        if aggregate_definition.kind_of?(Symbol) && klass.active_olap_aggregates.has_key?(aggregate_definition)
          Aggregate.from_configuration(klass, aggregate_definition)
        else
          Aggregate.create(klass, aggregate_definition.to_sym, aggregate_definition)
        end
      end
    end

    def initialize(klass, label, function, expression = nil, distinct = false)
      @klass      = klass
      @label      = label      
      @function   = function
      @expression = expression
      @distinct   = distinct
      @joins      = []
      @info       = {}
    end
    
    
    def self.create(klass, label, definition)
      case definition
      when Symbol
        return from_symbol(klass, label, definition)
      when String
        return from_string(klass, label, definition)
      when Hash
        return from_hash(klass, label, definition)
      else
        raise "Invalid aggregate definition: #{definition.inspect}"
      end
    end
    
    def self.from_configuration(klass, aggregate_name, label = nil)
      label = aggregate_name.to_sym if label.nil?
      if klass.active_olap_aggregates[aggregate_name].respond_to?(:call)
        return Aggregate.create(klass, label, klass.active_olap_aggregates[aggregate_name].call)
      else
        return Aggregate.create(klass, label, klass.active_olap_aggregates[aggregate_name])
      end     
    end    

    def self.from_hash(klass, label, hash)
      hash = hash.clone
      agg = Aggregate.create(klass, label, hash.delete(:expression))
      agg.joins.concat(hash[:joins].kind_of?(Array) ? hash.delete(:joins) : [hash.delete(:joins)]) if hash.has_key?(:joins)
      hash.each { |key, val| agg.info[key] = val }
      return agg
    end
    
    def self.from_string(klass, label, sql_expression)
      if sql_expression =~ /^(\w+)\((.+)\)$/
        return Aggregate.new(klass, label, $1.downcase.to_sym, $2, false)
      else
        raise "Invalid aggregate SQL expression: " + sql_expression
      end
    end
    
    def self.from_symbol(klass, label, aggregate_name)
      
      case aggregate_name
      when :count_all
        return Aggregate.new(klass, label, :count, '*', false) # with table name?
      when :count_distinct_all
        return Aggregate.new(klass, label, :count, '*', true)  # with table name?
      when :count
        return Aggregate.new(klass, label, :count, :id, false)        
      when :count_distinct
        return Aggregate.new(klass, label, :count, :id, true)
        
      else
        parts = aggregate_name.to_s.split('_')
        raise "Invalid aggregate name: #{symbol.inspect}" unless parts.length > 1
       
        distinct = false
        if parts[1] == 'distinct'
          parts.delete_at(1) 
          distinct = true
        end
      
        raise "Invalid aggregate name: #{symbol.inspect}" unless parts.length >= 2      
        #TODO: check field name and function name?
        return Aggregate.new(klass, label, parts[0].to_sym, parts[1..-1].join('_').to_sym, distinct)
      end
    end
    
    def to_sanitized_sql
      sql = @function.to_s.upcase! + '('
      sql << 'DISTINCT ' if @distinct
      sql << (@expression.kind_of?(Symbol) ? "#{quote_table}.#{quote_column(@expression)}" : @expression.to_s)
      sql << ") AS #{quote_column(@label)}"
    end
    
    def is_count_with_overlap?
      @function == :count_with_overlap
    end
    
    def cast_value(source)
      return nil if source.nil?
      (@function == :count) ? source.to_i : source.to_f # TODO: better?
    end
    
    def default_value
      (@function == :count) ? 0 : nil # TODO: better?
    end
    
    def self.values(aggregates, source)
      result = HashWithIndifferentAccess.new
      aggregates.each { |agg| result[agg.label] = agg.cast_value(source[agg.label.to_s]) }      
      return (aggregates.length == 1) ? result[aggregates.first.label] : result
    end
    
    def self.default_values(aggregates)
      result = HashWithIndifferentAccess.new
      aggregates.each { |agg| result[agg.label] = agg.default_value }      
      return (aggregates.length == 1) ? result[aggregates.first.label] : result
    end
    
    protected
    
    def quote_column(column)
      @klass.connection.send(:quote_column_name, column.to_s)
    end
    
    def quote_table
      @klass.connection.send(:quote_table_name, @klass.table_name)
    end
  end
  
end