module ActiveRecord::Olap
  
  class Category
    
    attr_reader :dimension, :label, :conditions, :info  
    
    # initializes a category, given the dimension it belongs to, a label,
    # and a definition. The definition should be a hash with at least the
    # key expression set to a usable ActiveRecord#find conditions
    def initialize(dimension, label, definition)
      @dimension = dimension
      @label = label
      @info = {}
      
      if definition.kind_of?(Hash) && definition.has_key?(:expression)
        @conditions = definition[:expression]
        @info = definition.reject { |k,v| k == :expression } 
      else
        @conditions = definition
      end
    end
    
    # Returns the index of this category in the corresponding dimension
    def index
      @dimension.category_index(@label)
    end
 
    # Returns a santized SQL expression for this category
    def to_sanitized_sql
      @dimension.klass.send(:sanitize_sql, @conditions)
    end
    
    def to_count_sql(count_what)
      "COUNT(DISTINCT CASE WHEN (#{to_sanitized_sql}) THEN #{count_what} ELSE NULL END) 
              AS #{@dimension.klass.connection.send(:quote_column_name, label.to_s)}"
    end
 
    # Returns the label of this category as a string
    def to_s
      return "nil" if label.nil?
      label.to_s
    end
    
  end
  
end