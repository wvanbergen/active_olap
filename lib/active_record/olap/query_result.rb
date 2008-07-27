module ActiveRecord::OLAP
  class QueryResult
    
    attr_accessor :klass
    attr_accessor :dimensions
    
    def initialize(klass, dimensions, query_result)
      @klass = klass
      @dimensions = dimensions
      @result = {}

      update_result_with(query_result)
    end
    
    def [](category)
      @result[category]
    end
    
    def depth
      @dimensions.length
    end
    
    def inspect
      @result.inspect
    end
    
    protected
    
    def update_result_with(query_result)
      rescan_for_unsets = false
      query_result.each do |row|
        discard_data = false
        result = @result
        values = row.attributes_before_type_cast
        
        (@dimensions.length - 1).times do |dim_index|
          # get the category for this dimension
          dim_cat = values.delete("dimension_#{dim_index}")
          if @dimensions[dim_index].is_field?
            @dimensions[dim_index].register_category(dim_cat)
          elsif dim_cat.nil?
            discard_data = true
            break 
          else
            dim_cat = dim_cat.to_sym
          end
          
          result[dim_cat] = {} if result[dim_cat].nil?
          result = result[dim_cat] 
        end
        
        unless discard_data
          if @dimensions.last.is_field?
            dimension_field_value = values["dimension_#{@dimensions.length - 1}"]
            @dimensions.last.register_category(dimension_field_value)
            result[dimension_field_value] = values['the_count_field'].to_i
          else
            result = {} if result.nil?
            values.each { |key, value| result[key.to_sym] = value.to_i } 
          end
        end
      end
      @result = traverse_result_for_unsets(dimensions, @result)
    end
        
    def traverse_result_for_unsets(dimensions, result, depth = 1)
      d = dimensions[depth - 1]
      d.categories.map(&:first).uniq.each do |cat|
        result[cat] = (depth >= dimensions.length) ? 0 : {}  unless result.has_key?(cat)
        result[cat] = traverse_result_for_unsets(dimensions, result[cat], depth + 1) unless depth >= dimensions.length
      end
      return result
    end
  end
end