module ActiveRecord::Olap
  
  class Cube
    
    attr_accessor :klass
    attr_accessor :dimensions
    attr_accessor :aggregates
    
    # Initializes a new OLAP cube. 
    def initialize(klass, dimensions, aggregates, query_result = nil)
      @klass      = klass
      @dimensions = dimensions
      @aggregates = aggregates
      
      # populates the cube with the query rsult if it is provided.
      unless query_result.nil?
        @result = []        
        populate_result_with(query_result)
        traverse_result_for_nils(@result)
      end
    end
    
    # Sums up all the values in this cube
    def sum(agg = nil)
      raise "Please provide the aggregate you want to sum." if self.aggregates.length > 1 && agg.nil?
      total_sum = 0
      self.each do |cat, value| 
          total_sum += (value.kind_of?(Cube) ? value.sum : (agg.nil? ? value : value[agg]))
      end
      return total_sum
    end
    
    # Returns the total number of cells in this cube. Note that this does not take aggregates into
    # account, so the result should me multiplied by the number of aggregates if you want to know
    # the total number of (numeric) values.
    def cell_count
      dimensions.inject(1) { |intermediate, dimension| intermediate * dimension.categories.length }
    end
    
    # Returns a reference to the internal array that holds ther raw results of this cube. 
    # Altering this array will alter the internals of the cube-object, so make sure you know what 
    # you are doing. Use to_a if you want to obtain a copy of the internal array
    def raw_results 
      @result
    end
    
    # Returns a clone of the internal array that holds ther raw results of this cube.
    def to_a
      @result.clone
    end
    
    # Returns the array of categories of the current (= first) dimension
    def categories
      @dimensions.first.categories
    end
    
    # Returns the current (first) dimension
    def dimension 
      @dimensions.first
    end
    
    # Returns the number of dimensions in this cube
    def depth
      @dimensions.length
    end
    
    # Returns the number of categories in the current (= first) dimension
    def breadth
      @result.length
    end
     
    # Switches the dimensions of a two-dimensional cube   
    def transpose
      raise "Can only transpose 2-dimensial results" unless depth == 2
      result_object = Cube.new(@klass, [@dimensions.last, @dimensions.first], @aggregates)
      result_object.result = @result.transpose
      return result_object      
    end
    
    def reorder_dimensions(*order)
      # IMPLEMENT ME      
    end
    
    def only_aggregate(aggregate_label)
      # IMPLEMENT ME
    end
    
    def only_dimension(dimension_index)
      # IMPLEMENT ME
    end
    
    def except_dimension(dimension_index)
      # IMPLEMENT ME
    end
    
    # Returns a part of the cube or a single cell
    # If the number of arguments matches the number of dimensions, a single cell is returned;
    # If the number of arguments is less that the number of dimensons, this function will return 
    # a cube with (dimensions.length - args.length) dimensions.
    def [](*args)
      result = @result.clone
      args.each_with_index do |cat_label, index|
        cat_index = @dimensions[index].category_index(cat_label)
        return nil if cat_index.nil?
        result = result[cat_index]
      end
      
      if result.kind_of?(Array)
        # build a new query_result object if not enoug dimensions were provided
        result_object = Cube.new(@klass, @dimensions[args.length...@dimensions.length], @aggregates)
        result_object.result = result
        return result_object
      else
        return result
      end
    end
    
    # Iterates over all the categories of the current dimension and their corresponding values.
    # The provided block should take two arguments: the first one will be the Category and
    # the second one will be the sub-cube or cell belonging to that category
    def each(&block)
     categories.each { |cat| yield(cat, self[cat.label]) }
    end
    
    # Maps all the categoies of the current dimension and their corresponding values. See each.
    def map(&block)
      result = []
      categories.each { |cat| result << yield(cat, self[cat.label]) }
      return result
    end
    
    protected

    # Set the result by hand. For internal use
    def result=(array)
      @result = array
    end

    # Walks over all the rows of the resultset to build the cube.
    def populate_result_with(query_result)
      
      query_result.each do |row|
        
        result = @result
        values = row.attributes_before_type_cast
        discard_data = false
                
        (@dimensions.length - 1).times do |dim_index|
          
          category_name = values.delete("dimension_#{dim_index}")
          if @dimensions[dim_index].is_field_dimension?
            # this field contains the value of the category_field, which should be used as category
            # this might be the first time this category is seen, so register it in the dimension
            category_index = @dimensions[dim_index].register_category(category_name)
            
          elsif category_name.nil?
            # this is a record for rows that did not fall in any of the categories of a dimension
            # therefore, this data can be discarded. This should not happen if an "other"-field is present!
            discard_data = true
            break 
            
          else
            # get the index of the category, which should exist
            category_index = @dimensions[dim_index].category_index(category_name.to_sym)
          end 
          
          # switch the result to the next dimension
          result[category_index] = [] if result[category_index].nil? # add a new dimension if needed
          result = result[category_index] # set the result to the next dimension for the next iteration
        end
        
        unless discard_data
          dim = @dimensions.last # only the last dimension is remaining
          if dim.is_field_dimension?
            # the last dimension is a field category.
            # every category is represented as a single row, with only one count per row
            dimension_field_value = values["dimension_#{@dimensions.length - 1}"]
            result[dim.register_category(dimension_field_value)] = Aggregate.values(@aggregates, values)
            
          elsif aggregates.length == 0
            # the last dimension is a category with possible overlap, using SUMs.
            # every category will have its number on this row
            result = [] if result.nil?
            values.each { |key, value| result[dim.category_index(key.to_sym)] = value.to_i }
            
          else
            # the last category is a normal category
            dimension_field_value = values["dimension_#{@dimensions.length - 1}"]
            result[dim.category_index(dimension_field_value.to_sym)] = Aggregate.values(@aggregates, values)
          end
        end
      end
    end
    
    # Makes sure all the values are set in the resulting array
    def traverse_result_for_nils(result, depth = 0)
      dim = @dimensions[depth]
      if dim == @dimensions.last
        # set all categories to 0 if no value is set
        dim.categories.length.times do |i|
          result[i] = Aggregate.default_values(@aggregates) if result[i].nil?
        end
      else
        # if no value set, create an empty array and iterate to the next dimension
        # so all values will be set to 0
        dim.categories.length.times do |i|
          result[i] = [] if result[i].nil?
          traverse_result_for_nils(result[i], depth + 1)
        end        
      end
    end
  end
end