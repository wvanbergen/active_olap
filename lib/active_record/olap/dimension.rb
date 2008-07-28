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
      sql_fragments = @categories.map do |category, cat_info|
        "SUM(#{@klass.send(:sanitize_sql, cat_info[:expression])}) AS #{@klass.connection.send(:quote_column_name, category)}"
      end
      return sql_fragments.join(', ')
    end
    
    def to_group_expression(variable_name)
      if @category_field
        "#{@klass.connection.send(:quote_column_name, @category_field)} AS #{@klass.connection.send(:quote_column_name, variable_name)}"
      else
        "#{generate_groupable_case_expession(@categories.clone)} AS #{@klass.connection.send(:quote_column_name, variable_name)}"
      end
    end

    def condition_for(cat)
      if @category_field
        { @category_field => cat }
      else 
        "(#{@klass.send(:sanitize_sql, self[cat][:expression])})"
      end
    end

    def register_category(cat)
      @categories << [cat, {:expression => {@category_field => cat}}] # unless has_category?(cat)
    end

    def find_category(cat)
      c = @categories.detect { |cat_info| cat_info.first == cat }
      c = c.last unless c.nil?
      return c
    end
    
    def [](cat)
      find_category(cat)
    end
    
    def is_field?
      !@category_field.nil?
    end
    
    def has_category?(cat)
      !find_category(cat).nil?
    end

    protected

    # mysql only?
    def generate_groupable_if_expession(categories)
      category = categories.shift # pop?
      if categories.length > 0
        sql = @klass.send(:sanitize_sql, ["IF(#{@klass.send(:sanitize_sql, category.last[:expression])}), (#{generate_groupable_if_expession(categories)}), ?)", category.first.to_s])
      else
        sql = @klass.send(:sanitize_sql, ["IF(#{@klass.send(:sanitize_sql, category.last[:expression])}), ?, NULL)", category.first.to_s])
      end
      return sql
    end

    def generate_groupable_case_expession(categories)
      whens = categories.map { |category| @klass.send(:sanitize_sql, ["WHEN (#{@klass.send(:sanitize_sql, category.last[:expression])}) THEN ?", category.first.to_s]) }
      return "CASE #{whens.join(' ')} ELSE NULL END";
    end
    
   
    
    def generate_other_condition
      all_categories = @categories.map { |category| "(#{@klass.send(:sanitize_sql, category.last[:expression])})" }.join(' OR ') 
      "((#{all_categories}) IS NULL OR NOT(#{all_categories}))"
    end    

    def initialize(klass, definition)
      @klass = klass
      @categories = []

      if definition.kind_of?(Hash)
        
        if definition.has_key?(:categories)
          
          skip_other = false
          definition[:categories].each do |key, value|
            skip_other = true if key == :other             
            if value 
              @categories << (value.kind_of?(Hash) && value.has_key?(:expression) ? [key, value] : [key, {:expression => value}])
            end
          end
          @categories << [:other, {:expression => generate_other_condition }] unless skip_other
          
        elsif definition.has_key?(:trend)
          
          @categories = generate_trend_categories(definition[:trend])
          
        elsif definition.has_key?(:field)
          
          # TODO: check whether this is an existing field
          @category_field = definition[:field]
        else
          raise "Invalid category definition! " + definition.inspect          
        end
      elsif definition.kind_of?(Symbol)
        # TODO: check whether this is an existing field
        @category_field = definition
      else
        raise "Invalid category definition! " + definition.inspect
      end      
    end
    
    def generate_trend_categories(trend_definition)
      period_count     = trend_definition.delete(:period_count)    || 14
      period_length    = trend_definition.delete(:period_length)   || 1.days
      trend_end        = trend_definition.delete(:end)             || Time.now.utc.midnight
      timestamp_field  = trend_definition.delete(:timestamp_field)
      
      field = @klass.connection.send :quote_column_name, timestamp_field
      periods = Array.new(period_count)
      period_end = trend_end
      period_count.downto(1) do |i|
        periods[i - 1] = ["period_#{i}".to_sym, {:begin => period_end - period_length, :end  => period_end,
            :expression => ["#{field} >= ? AND #{field} < ?", period_end - period_length, period_end] }]
        period_end  -= period_length
      end

      return periods
    end    
  end
end