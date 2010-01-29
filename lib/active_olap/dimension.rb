module ActiveOLAP
  
  class Dimension

    attr_reader :klass
    attr_reader :categories
    attr_reader :category_field
    attr_reader :info
    
    attr_reader :joins
    attr_reader :conditions
    
    # creates a new Dimension, given a definition.
    # The definition can be:
    # - A name (Symbol) of registered definition
    # - A name (Symbol) of a field in the corresponding table
    # - A hash, with at most one of the following keys set
    #   - :categories -> for custom categories
    #   - :trend      -> for a trend dimension
    #   - :field      -> for a table field dimension (similar to passing a Symbol)
    def self.create(klass, definition = nil)
      return klass if klass.kind_of? Dimension      
      
      case definition
      when Dimension
        return definition
      when Symbol
        if klass.active_olap_dimensions.has_key?(definition)
          if klass.active_olap_dimensions[definition].respond_to?(:call)
            return Dimension.new(klass, klass.active_olap_dimensions[definition].call)
          else
            return Dimension.new(klass, klass.active_olap_dimensions[definition])
          end
        else
          return Dimension.new(klass, definition)        
        end
      when Array
        if klass.active_olap_dimensions.has_key?(definition.first)
          return Dimension.new(klass, klass.active_olap_dimensions[definition.shift].call(*definition))
        else 
          return Dimension.new(klass, definition)
        end
      else
        return Dimension.new(klass, definition)
      end
    end

    # Builds a SUM expression for this dimension.
    def to_count_with_overlap_sql
      
      count_value = @klass.connection.send(:quote_table_name, @klass.table_name) + '.' + 
                    @klass.connection.send(:quote_column_name, :id) # TODO: other column than id
        
      @categories.map { |category| category.to_count_sql(count_value) }.join(', ')
    end
    
    # Builds a CASE expression for this dimension.
    def to_case_expression(variable_name)
      if @category_field
        quoted_field_name = @klass.connection.send(:quote_table_name, @klass.table_name) + '.' + 
                                      @klass.connection.send(:quote_column_name, @category_field)
                                      
        "#{quoted_field_name} AS #{@klass.connection.send(:quote_column_name, variable_name)}"
      else
        raise "This dimension does not have any categories!" if @categories.empty?
        whens = @categories.map { |category| @klass.send(:sanitize_sql, ["WHEN (#{category.to_sanitized_sql}) THEN ?", category.label.to_s]) }
        "CASE #{whens.join(' ')} ELSE NULL END AS #{@klass.connection.send(:quote_column_name, variable_name)}";
      end
    end

    # Registers a category in this dimension.
    # This function is called when a dimension is created and the categories are known or
    # while the query result is being populated for dimensions with unknown categories.
    def register_category(cat_label, definition = nil)
      unless has_category?(cat_label)
        definition = {:expression => { @category_field => cat_label }} if definition.nil? && @category_field
        cat = Category.new(self, cat_label, definition)
        @categories << cat
        return (@categories.length - 1)
      else
        return category_index(cat_label)
      end
    end
    
    # Returns a category, given a category label
    def [](label)
      category_by_label(label)
    end
    
    # Returns all the category labels
    def category_labels 
      @categories.map(&:label)
    end
    
    # Checks whether this dimension has a category with the provided label
    def has_category?(label)
      @categories.any? { |cat| cat.label == label }
    end
    
    # Returns the index in this dimension of a category identified by its label 
    def category_index(label)
      @categories.each_with_index { |cat, index| return index if cat.label == label }
      return nil
    end
    
    # Returns a category, given its index
    def category_by_index(index)
      @categories[index]
    end
    
    # Returns a category, given a category label
    def category_by_label(label)
      @categories.detect { |cat| cat.label == label }
    end    
    
    # checks whether thios is a table field dimension which categories are unknown beforehand
    def is_field_dimension?
      !@category_field.nil?
    end
    
    def is_time_dimension?
      @info.has_key?(:trend) && @info[:trend] == true
    end
    
    def is_custom_dimension?
      !is_field_dimension? && !is_time_dimension?
    end
    
    def has_overlap?
      @info.has_key?(:overlap) && @info[:overlap] == true
    end
    
    # Returns a sanitized SQL expression for a given category
    def sanitized_sql_for(cat)
      cat_conditions = is_field_dimension? ? @klass.send(:sanitize_sql, { @category_field => cat }) : self[cat].to_sanitized_sql
      @klass.send(:merge_conditions, cat_conditions, @conditions) 
    end
    
    protected
    
    # Generates an SQL expression for the :other-category
    def generate_other_condition
      all_categories = @categories.map { |category| "(#{category.to_sanitized_sql})" }.join(' OR ') 
      "((#{all_categories}) IS NULL OR NOT(#{all_categories}))"
    end    

    # Initializes a new Dimension object. See Dimension#create
    def initialize(klass, definition)
      @klass = klass
      @categories = []

      @info = {}

      @joins = []
      @conditions = nil
      
      case definition
      when Hash
        hash = definition.clone
        @conditions = hash.delete(:conditions)
        @joins += hash[:joins].kind_of?(Array) ? hash.delete(:joins) : [hash.delete(:joins)] if hash.has_key?(:joins)
        
        if hash.has_key?(:categories)
          generate_custom_categories(hash.delete(:categories))
          
        elsif hash.has_key?(:trend)
          generate_trend_categories(hash.delete(:trend))
          
        elsif hash.has_key?(:field)
          generate_field_dimension(hash.delete(:field))

        else
          raise "Invalid category definition! " + definition.inspect          
        end
        
        # make the remaining fields available in the info object
        @info.merge!(hash)
        
      when Symbol
        generate_field_dimension(definition)
        
      else
        raise "Invalid category definition! " + definition.inspect
      end      
    end
    
    def generate_field_dimension(field)
      case field
      when Hash
        @category_field = field[:column].to_sym
      else  
        @category_field = field.to_sym        
      end
      
      unless @klass.column_names.include?(@category_field.to_s)
        raise "Could not create dimension for unknown field #{@category_field}" 
      end
    end
    
    def generate_custom_categories(categories)
      skip_other = false
      categories.to_a.each do |category|
        skip_other = true if category.first == :other
        register_category(category.first, category.last) if category.last
      end
      register_category(:other, :expression => generate_other_condition) unless skip_other
    end
    
    def generate_trend_categories(trend_definition)
      period_count     = trend_definition.delete(:periods) || trend_definition.delete(:period_count)    || 14      
      period_length    = trend_definition.delete(:period_length)   || 1.days
      trend_end        = trend_definition.delete(:end)             || Time.now.utc.midnight + 1.day
      trend_begin      = trend_definition.delete(:begin)
      timestamp_field  = trend_definition.delete(:timestamp_field)
      
      if !trend_end.nil? && trend_begin.nil?
        trend_begin = trend_end - (period_count * period_length)
      end
      
      
      field = @klass.connection.send :quote_column_name, timestamp_field
      period_begin = trend_begin
      period_count.times do |i|
        register_category("period_#{i}".to_sym, {:begin => period_begin, :end => period_begin + period_length,
                      :expression => ["#{field} >= ? AND #{field} < ?", period_begin, period_begin + period_length] })
        period_begin  += period_length
      end
      
      # update conditions by only querying records that fall in any periods.
      @conditions = @klass.send(:merge_conditions, @conditions, ["#{field} >= ? AND #{field} < ?", trend_begin, period_begin])
      @info[:trend] = true
    end    
  end
end