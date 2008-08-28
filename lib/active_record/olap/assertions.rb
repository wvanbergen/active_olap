module ActiveRecord::Olap::Assertions
  
  # tests whether Active OLAP is enabled for a given class, by checking
  # whether the class responds to certain methods like olap_query
  def assert_active_olap_enabled(klass, message = "Active OLAP is not enabled for this class!")
    assert klass.respond_to?(:active_olap_dimensions), message
    assert klass.respond_to?(:active_olap_aggregates), message
    assert klass.respond_to?(:olap_query), message
    assert klass.respond_to?(:olap_drilldown), message    
  end
  
  # tests whether a given cube is a valid Active OLAP cube and has the expected dimensions
  # you can specify the number of dimenions as an integer (say n), or as an array of n integers,
  # in which each element is the number of categories that should be in that dimension. You can 
  # use :unknown if this is not known beforehand
  #
  # examples:
  #
  # assert_active_olap_cube cube, 2 
  # => checks for the existence of two dimensions
  #
  # assert_active_olap_cube cube, [3, :unknown] 
  # => Checks for the existence of two dimensions. 
  #    - The first dimension should have 3 catgeories
  #    - The number of categories in the second dimension is unknown
  def assert_active_olap_cube(cube, dimensions = nil)
    assert_kind_of ActiveRecord::Olap::Cube, cube
    if dimensions.kind_of?(Array)
      assert_equal dimensions.length, cube.depth
      dimensions.each_with_index do |category_count, index|
        assert_equal category_count, cube.dimensions[index].categories.length unless category_count == :unknown
      end
    elsif dimensions.kind_of?(Numeric)
      assert_equal dimensions, cube.depth   
    end
  end
  
end