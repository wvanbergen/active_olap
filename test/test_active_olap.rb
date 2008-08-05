require "#{File.dirname(__FILE__)}/test_helper"

class ActiveRecord::Olap::Test < Test::Unit::TestCase
  
  include ActiveOlapOlapTestHelper
  
  def setup
    create_db    
    create_corpus
  end

  def teardown
    cleanup_db
  end
  
  # --- TESTS ---------------------------------

  def test_wrong_overlap_dimension_usage
    
    begin
      cube = OlapTest.olap_query :with_overlap, :category
      assert false, "An exception should have been thrown"
    rescue
      assert true
    end
    
    begin
      cube = OlapTest.olap_query :with_overlap, :aggregate => :avg_int_field
      assert false, "An exception should have been thrown"
    rescue
      assert true
    end
  end

  def test_with_associations
    cube = OlapTest.olap_query :category, :aggregate => [:count_distinct, :total_price]
    assert_valid_cube cube, [5]
    assert_equal 1, cube[:no_category][:count_distinct]
    assert_equal 5.7, cube[:no_category][:total_price]
    assert_equal nil, cube[:first_cat][:total_price]    
    
    cube = OlapTest.olap_query(:in_association)
    assert_valid_cube cube, [3]
    assert_equal 1, cube[:first]
    assert_equal 1, cube[:second]
    assert_equal 4, cube[:other]        
  end
  
  def test_time_dimension
    cube = OlapTest.olap_query(:the_time)
    assert_valid_cube cube, [20]
    
    cube = OlapTest.olap_query([:the_time, {:period_count => 10}])
    assert_valid_cube cube, [10]
  end
  
  def test_with_aggregates
    # defined using a smart symbol
    cube = OlapTest.olap_query(:category, :aggregate => :sum_int_field)
    assert_equal 33, cube[:first_cat]    
    assert_equal 77, cube[:second_cat]
    assert_equal 33, cube[:no_category]    
    assert_equal nil,  cube[:third_cat]        
    assert_equal nil,  cube[:other]     
      
    # defined using the configurator
    cube = OlapTest.olap_query(:category, :aggregate => :sum_int)
    assert_equal 33, cube[:first_cat]    
    assert_equal 77, cube[:second_cat]
      
    # using an SQL expression
    cube = OlapTest.olap_query(:category, :aggregate => 'avg(olap_tests.int_field)')
    assert_equal 33.0, cube[:first_cat]    
    assert_equal (33.0 + 44.0) / 2, cube[:second_cat]
    assert_equal 33.0, cube[:no_category]    
    assert_equal nil,  cube[:third_cat]        
    assert_equal nil,  cube[:other]
  
    # multiple aggregates
    cube = OlapTest.olap_query(:category, :aggregate => [:count_distinct, 'avg(olap_tests.int_field)', :sum_int ])
    assert_equal 1, cube.depth
    assert_equal 5, cube.breadth
  
    assert_equal 1, cube[:first_cat][:count_distinct]
    assert_equal 33.0, cube[:first_cat][:sum_int]
    assert_equal (33.0 + 44.0) / 2, cube[:second_cat]['avg(olap_tests.int_field)']
    
    # array notation
    cube = OlapTest.olap_query(:category, :aggregate => [:count_distinct, 'avg(olap_tests.int_field)', :sum_int] )
    assert_equal 1, cube.depth
    assert_equal 5, cube.breadth
  
    assert_equal 1, cube[:first_cat][:count_distinct]
    assert_equal 33.0, cube[:first_cat][:sum_int]
    assert_equal (33.0 + 44.0) / 2, cube[:second_cat]['avg(olap_tests.int_field)']
  end
  
  def test_with_overlap
    cube = OlapTest.olap_query(:with_overlap)
    assert_valid_cube cube, [3]
    
    assert_equal 2, cube[:like_23]
    assert_equal 3, cube[:starts_with_1]
    assert_equal 1, cube[:other]
        
    assert cube.sum > OlapTest.count
  end
  
  def test_conditions
    cube = OlapTest.olap_query(:field => :category_field, :conditions => {:datetime_field => nil})
    assert_equal 1, cube.depth
    assert_equal 2, cube.sum
    
    assert_equal 1, OlapTest.olap_drilldown({:field => :category_field, :conditions => {:datetime_field => nil}} => 'second_cat').count
  end
  
  def test_config_with_lambda_trend_and_transpose
    
    cube = OlapTest.olap_query(:category, :my_trend)
    assert_equal 5, cube.breadth # 4 + other
    assert_equal 2, cube.depth
    assert_equal :first_cat, cube.dimension.categories.first.label
    
    # switch the dimensions using transpose
    cube = cube.transpose
    
    assert_equal 20, cube.breadth # 20 periods
    assert_equal 2, cube.depth
    
  end  
  
  def test_with_config
    cube = OlapTest.olap_query(:category)
    assert_equal 1,   cube[:first_cat]
    assert_equal 2,   cube[:second_cat]
    assert_equal 0,   cube[:third_cat]
    assert_equal nil, cube[:fourth_cat]
    assert_equal 1,   cube[:no_category]
  end
  
  
  def test_with_periods
    dimension_1 = { :trend => { :timestamp_field => :datetime_field, :period_count => 5}}
    dimension_2 = :category_field
  
    cube = OlapTest.olap_query(dimension_1, dimension_2)

    assert_valid_cube  cube, [5, :unknown]
    
    assert_equal 1, cube[:period_2, 'first_cat']
    assert_equal 0, cube[:period_2, 'second_cat']        
    assert_equal 0, cube[:period_0, 'first_cat']        
    assert_equal 1, cube[:period_0, 'second_cat']    
    assert_equal 0, cube[:period_3, 'second_cat']
    assert_equal 0, cube[:period_1, 'first_cat']            
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1 => :period_4, dimension_2 => 'second_cat').count
  end
  
  def test_with_three_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field   
    dimension_3 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    cube = OlapTest.olap_query(dimension_1, dimension_2, dimension_3)
    assert_valid_cube cube, [2, :unknown, 2]
    
    # check that every value is set
    assert_equal 1, cube[:datetime_field_set, 'first_cat',:string_like_2]
    assert_equal 0, cube[:datetime_field_set, 'first_cat',:other]
    assert_equal 0, cube[:datetime_field_set, 'second_cat',:string_like_2]
    assert_equal 1, cube[:datetime_field_set, 'second_cat',:other]
    assert_equal 0, cube[:datetime_field_set, nil,:string_like_2]
    assert_equal 0, cube[:datetime_field_set, nil,:other]
    assert_equal 0, cube[:other, 'first_cat',:string_like_2]
    assert_equal 0, cube[:other, 'first_cat',:other]
    assert_equal 1, cube[:other, 'second_cat',:string_like_2]
    assert_equal 0, cube[:other, 'second_cat',:other]    
    assert_equal 1, cube[:other, nil,:string_like_2]
    assert_equal 0, cube[:other, nil,:other]    
    
    # checking that drilling down results in cubes as well
    intermediate_cube = cube[:other]
    assert_valid_cube intermediate_cube, [:unknown, 2]
    assert_valid_cube cube[:other, 'second_cat'], [2]
    assert_valid_cube cube[:other]['second_cat'], [2]

    assert 1, intermediate_cube['second_cat'][:string_like_2]
    assert 1, cube[:other, 'second_cat'][:string_like_2]    
    
    # check for order preservation
    found_categories = []
    intermediate_cube.each do |category, drilled_down_cube|
      assert_valid_cube drilled_down_cube, [2]
      found_categories << category.label
    end
    assert_equal ['first_cat', 'second_cat', nil], found_categories
  end
  
  def test_condition_field_with_two_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field
  
    cube = OlapTest.olap_query(dimension_1, dimension_2)
    assert_valid_cube cube, [2, :unknown]
  
    assert_equal 1, cube[:datetime_field_set, 'first_cat']
    assert_equal 1, cube[:datetime_field_set, 'second_cat']
    assert_equal 0, cube[:datetime_field_set, nil]    
    assert_equal 0, cube[:other, 'first_cat']    
    assert_equal 1, cube[:other, 'second_cat']    
    assert_equal 1, cube[:other, nil]
  
    cube = OlapTest.olap_query(dimension_2, dimension_1)
    assert_valid_cube cube, [:unknown, 2]
  
    assert_equal 1, cube['first_cat', :datetime_field_set]
    assert_equal 1, cube['second_cat', :datetime_field_set]
    assert_equal 1, cube['second_cat', :other]
    assert_equal 1, cube[nil, :other]
  end
  
  def test_condition_field
    cube = OlapTest.olap_query(:category_field)
    assert_valid_cube cube, [:unknown]
    
    assert_equal 1,   cube['first_cat']
    assert_equal 2,   cube['second_cat']
    assert_equal nil, cube['third_cat']    
    assert_equal nil, cube['fourth_cat']
    assert_equal 1,   cube[nil]    
    
    assert_equal 1, OlapTest.olap_drilldown(:category_field => nil).count
  end
  
  def test_two_dimensions
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil} } }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    cube = OlapTest.olap_query(dimension_1, dimension_2)
    assert_valid_cube cube, [2, 2]
    
    assert_equal 0, cube[:datetime_field_not_set,:other]
    assert_equal 2, cube[:datetime_field_not_set,:string_like_2]    
    assert_equal 1, cube[:other,:other]
    assert_equal 1, cube[:other,:string_like_2]    
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1 => :datetime_field_not_set, dimension_2 => :other).length
    assert_equal 2, OlapTest.olap_drilldown(dimension_1 => :datetime_field_not_set, dimension_2 => :string_like_2).length
        
  end
  
  def test_two_dimensions_without_other
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil }, :other => false} }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'], :other => false } }
    
    cube = OlapTest.olap_query(dimension_1, dimension_2)
    assert_valid_cube cube, [1, 1]
    
    assert_nil cube[:other]
    assert_nil cube[:datetime_field_not_set,:other]
    assert_equal 2, cube[:datetime_field_not_set,:string_like_2]
    
  end  
  
  def test_olap_query
    cube = OlapTest.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_valid_cube cube, [2]
    assert_equal 2, cube[:datetime_field_not_set]
    assert_equal 2, cube[:other]
    
    cube = OlapTest.olap_query :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] }
    assert_valid_cube cube, [2]
    assert_equal 3, cube[:string_like_2]
    assert_equal 1, cube[:other]    
    
    found_categories = []
    cube.each do |category, res|
      assert_kind_of Numeric, res
      found_categories << category.label
    end
    # cassert the correct order for the categories
    assert_equal [:string_like_2, :other], found_categories
  end
  
  def test_drilldown
    unsets = OlapTest.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :datetime_field_not_set)
    assert_equal 2, unsets.length
  
    others = OlapTest.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :other)
    assert_equal 2, others.length  
  end
   
  def test_olap_query_within_scope
    assert_equal 3, OlapTest.int_field_33.count
    cube = OlapTest.int_field_33.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_valid_cube cube, [2]
    assert_equal 1, cube[:datetime_field_not_set]
    assert_equal 2, cube[:other]   # the other record does not fall within the scope int_field_33
      
    unsets = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :datetime_field_not_set)
    assert_equal 1, unsets.length
  
    others = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :other)
    assert_equal 2, others.length    
  end
  
  # the actual SQL expression strings are connection specific,
  # For this test, they are in SQLite3 format
  def test_other_condition
    dimension = ActiveRecord::Olap::Dimension.create(OlapTest, :categories => { :datetime_field_set => {:datetime_field => nil}})
    assert_kind_of ActiveRecord::Olap::Dimension, dimension
    assert_equal '((("olap_tests"."datetime_field" IS NULL)) IS NULL OR NOT(("olap_tests"."datetime_field" IS NULL)))', dimension[:other].to_sanitized_sql
    
    dimension = { :categories => { :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::Olap::Dimension.create(OlapTest, dimension)
    assert_kind_of String, dimension[:other].conditions
    
    dimension = { :categories => { :other => false, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::Olap::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => nil, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::Olap::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => ['willem = ?', "grea't"], :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::Olap::Dimension.create(OlapTest, dimension)
    assert_equal ["willem = ?", "grea't"], dimension[:other].conditions
    assert_equal "willem = 'grea''t'", dimension[:other].to_sanitized_sql
  end
end