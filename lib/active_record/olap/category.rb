module ActiveRecord::OLAP
  
  class Category
    
    attr_reader :dimension, :label, :conditions, :info  
    
    def initialize(dimension, label, definition)
      @dimension = dimension
      @label = label
      @info = {}
      
      if definition.kind_of?(Hash) && definition.has_key?(:expression)
        @conditions = definition[:expression]
        @info = definition.delete_if { |k,v| k == :expression } 
      else
        @conditions = definition
      end
    end
    
    def index
      @dimension.category_index(@label)
    end
 
    def to_sanitized_sql
      @dimension.klass.send(:sanitize_sql, @conditions)
    end
    
    
    def inspect
      "OLAP::Category(#{@label.inspect}, #{@conditions.inspect})"
    end
  end
  
end