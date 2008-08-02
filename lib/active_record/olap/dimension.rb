module ActiveRecord::OLAP
  class Dimension

    attr_reader :klass
    attr_reader :categories
    attr_reader :category_field

    # creates a new Dimension, given a definition.
    # The definition can be:
    # - A name (Symbol) of registered definition
    # - A name (Symbol) of a field in the corresponding table
    # - A hash, with at most one of the following keys set
    #   - :categories -> for custom categories
    #   - :trend      -> for a trend dimension
    #   - :field      -> for a table field dimension (similar to passing a Symbol)
    def self.create(klass, definition = nil, scope = nil)
      return klass if klass.kind_of? Dimension      
      
      case definition
      when Dimension
        return definition
      when Symbol
        if klass.active_olap_dimensions.has_key?(definition)
          if klass.active_olap_dimensions[definition].respond_to?(:call)
            return Dimension.new(klass, klass.active_olap_dimensions[definition].call, scope)
          else
            return Dimension.new(klass, klass.active_olap_dimensions[definition], scope)
          end
        else
          return Dimension.new(klass, definition, scope)        
        end
      when Array
        if klass.active_olap_dimensions.has_key?(definition.first)
          return Dimension.new(klass, klass.active_olap_dimensions[definition.shift].call(*definition), scope)
        else 
          return Dimension.new(klass, definition, scope)
        end
      else
        return Dimension.new(klass, definition, scope)
      end
    end

    # Builds a SUM expression for this dimension.
    def to_aggregate_expression
      sql_fragments = @categories.map do |category|
        "SUM(#{category.to_sanitized_sql}) AS #{@klass.connection.send(:quote_column_name, category.label.to_s)}"
      end
      return sql_fragments.join(', ')
    end
    
    # Builds a CASE expression for this dimension.
    def to_group_expression(variable_name)
      if @category_field
        "#{@klass.connection.send(:quote_column_name, @category_field)} AS #{@klass.connection.send(:quote_column_name, variable_name)}"
      else
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
    
    def is_trend_dimension?
      @is_trend
    end
    
    def is_custom_dimension?
      !is_field_dimension? && !is_trend_dimension?
    end
    
    # Returns a sanitized SQL expression for a given category
    def sanitized_sql_for(cat)
      is_field_dimension? ? @klass.send(:sanitize_sql, { @category_field => cat }) : self[cat].to_sanitized_sql
    end
    
    protected
    
    def update_scope
      
    end
    
    # Generates an SQL expression for the :other-category
    def generate_other_condition
      all_categories = @categories.map { |category| "(#{category.to_sanitized_sql})" }.join(' OR ') 
      "((#{all_categories}) IS NULL OR NOT(#{all_categories}))"
    end    

    # Initializes a new Dimension object. See Dimension#create
    def initialize(klass, definition, scope_conditions = nil)
      @klass = klass
      @categories = []
      @is_trend = false
      
      case definition
      when Hash
        scope_conditions << definition[:conditions] if scope_conditions.kind_of?(Array) && definition.has_key?(:conditions)
        
        if definition.has_key?(:categories)
          generate_custom_categories(definition[:categories])
          
        elsif definition.has_key?(:trend)
          generate_trend_categories(definition[:trend], scope_conditions)
          
        elsif definition.has_key?(:field)
          generate_field_dimension(definition[:field])

        else
          raise "Invalid category definition! " + definition.inspect          
        end
        
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
    
    def generate_trend_categories(trend_definition, scope_conditions = nil)
      @is_trend = true
      
      period_count     = trend_definition.delete(:period_count)    || 14
      period_length    = trend_definition.delete(:period_length)   || 1.days
      trend_end        = trend_definition.delete(:end)             || Time.now.utc.midnight
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
      
      scope_conditions << ["#{field} >= ? AND #{field} < ?", trend_begin, period_begin]
      
    end    
  end
end