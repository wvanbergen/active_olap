module ActiveRecord::OLAP
  class Dimension

    attr_reader :klass
    attr_reader :categories
    attr_reader :category_field

    def self.create(klass, definition = nil)
      return klass      if klass.kind_of? Dimension      
      return definition if definition.kind_of? Dimension            
      return Dimension.new(klass, definition)
    end

    def to_aggregate_expression
      sql_fragments = @categories.map do |category|
        "SUM(#{category.to_sanitized_sql}) AS #{@klass.connection.send(:quote_column_name, category.label.to_s)}"
      end
      return sql_fragments.join(', ')
    end
    
    def to_group_expression(variable_name)
      if @category_field
        "#{@klass.connection.send(:quote_column_name, @category_field)} AS #{@klass.connection.send(:quote_column_name, variable_name)}"
      else
        whens = @categories.map { |category| @klass.send(:sanitize_sql, ["WHEN (#{category.to_sanitized_sql}) THEN ?", category.label.to_s]) }
        "CASE #{whens.join(' ')} ELSE NULL END AS #{@klass.connection.send(:quote_column_name, variable_name)}";
      end
    end

    def register_category(cat_label, definition = nil)
      puts "Checking for category: #{cat_label.inspect}"
      unless has_category?(cat_label)
        puts "#{cat_label.inspect} not found, registering..."
        definition = {:expression => { @category_field => cat_label }} if definition.nil? && @category_field
        cat = Category.new(self, cat_label, definition)
        @categories << cat
        return (@categories.length - 1)
      else
        puts "Reusing #{cat_label.inspect}..."
        return category_index(cat_label)
      end
    end
    
    def [](label)
      @categories.detect { |cat| cat.label == label }
    end
    
    def category_labels 
      @categories.map(&:label)
    end
        
    def has_category?(label)
      @categories.any? { |cat| cat.label == label }
    end
    
    def category_index(label)
      @categories.each_with_index { |cat, index| return index if cat.label == label }
      return nil
    end
    
    def category_by_index(index)
      @categories[index]
    end
    
    def is_field_dimension?
      !@category_field.nil?
    end
    
    def sanitized_sql_for(cat)
      is_field_dimension? ? @klass.send(:sanitize_sql, { @category_field => cat }) : self[cat].to_sanitized_sql
    end
    
    protected
    
    def generate_other_condition
      all_categories = @categories.map { |category| "(#{category.to_sanitized_sql})" }.join(' OR ') 
      "((#{all_categories}) IS NULL OR NOT(#{all_categories}))"
    end    

    def initialize(klass, definition)
      @klass = klass
      @categories = []
      
      case definition
      when Hash
        
        if definition.has_key?(:categories)
          generate_custom_categories(definition[:categories])
          
        elsif definition.has_key?(:trend)
          generate_trend_categories(definition[:trend])
          
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
      # TODO: check whether this is an existing field        
      case field
      when Hash
        @category_field = field[:column].to_sym
      else  
        @category_field = field.to_sym        
      end

    end
    
    def generate_custom_categories(categories)
      skip_other = false
      categories.each do |key, value|
        skip_other = true if key == :other
        register_category(key, value) if value
      end
      register_category(:other, :expression => generate_other_condition) unless skip_other
    end
    
    def generate_trend_categories(trend_definition)
      period_count     = trend_definition.delete(:period_count)    || 14
      period_length    = trend_definition.delete(:period_length)   || 1.days
      trend_end        = trend_definition.delete(:end)             || Time.now.utc.midnight
      timestamp_field  = trend_definition.delete(:timestamp_field)
      
      field = @klass.connection.send :quote_column_name, timestamp_field
      periods = Array.new(period_count)
      period_begin = trend_end - (period_count * period_length)
      period_count.times do |i|
        register_category("period_#{i}".to_sym, {:begin => period_begin, :end => period_begin + period_length,
                      :expression => ["#{field} >= ? AND #{field} < ?", period_begin, period_begin + period_length] })
        period_begin  += period_length
      end
      return periods
    end    
  end
end