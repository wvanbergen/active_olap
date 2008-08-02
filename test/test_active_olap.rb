require "#{File.dirname(__FILE__)}/test_helper"

class OlapTest < ActiveRecord::Base  
  
  named_scope :int_field_33, :conditions => {:int_field => 33}
  
  enable_active_olap do |olap|
    
    olap.dimension :category, :categories => [
          [:first_cat,   { :category_field => 'first_cat' }],
          [:second_cat,  { :category_field => 'second_cat' }],
          [:third_cat,   { :category_field => 'third_cat' }],
          [:no_category, { :category_field => nil }] 
        ]
        
    olap.dimension :my_trend, lambda { {:trend => {
          :timestamp_field => :datetime_field,
          :period_count    => 20,
          :period_length   => 1.day,
          :trend_end       => Time.now.midnight
        } } }
    
    olap.time_dimension :the_time, :datetime_field, {:period_count => 20, :period_length => 1.day}
        
    olap.dimension :with_overlap, :categories => {
          :starts_with_1 => "string_field LIKE '1%'",
          :like_23       => "string_field LIKE '%23%'"
        }
        
    olap.aggregate :sum_int, :sum_int_field
  end
  
end

class ActiveRecord::OLAP::Test < Test::Unit::TestCase
  
  # creates a memory based database to test OLAP queries
  def setup
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

    ActiveRecord::Schema.define(:version => 1) do
      create_table :olap_tests do |t|
        t.string   :string_field
        t.integer  :int_field
        t.string   :category_field
        t.datetime :datetime_field
        t.timestamps
      end
    end
    
    create_corpus
  end
  
  # creates some data to perform OLAP queries on
  def create_corpus
    OlapTest.create!({ :string_field => '123', :int_field => 33, :category_field => 'first_cat',  :datetime_field => 2.day.ago })
    OlapTest.create!({ :string_field => '123', :int_field => 44, :category_field => 'second_cat', :datetime_field => nil })
    OlapTest.create!({ :string_field => '',    :int_field => 33, :category_field => 'second_cat', :datetime_field => 4.days.ago })    
    OlapTest.create!({ :string_field => '12',  :int_field => 33, :category_field => nil,  :datetime_field => nil })        
  end

  # destroys all the data in the memory-based database
  def teardown
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end
  end
  
  # --- TESTS ---------------------------------

  def test_time_dimension
    result = OlapTest.olap_query(:the_time)
    assert_equal 1, result.depth 
    assert_equal 20, result.breadth
    
    result = OlapTest.olap_query([:the_time, {:period_count => 10}])
    assert_equal 1, result.depth 
    assert_equal 10, result.breadth
  end

  def test_with_aggregates
    # defined using a smart symbol
    result = OlapTest.olap_query(:category, :aggregate => :sum_int_field)
    assert_equal 33, result[:first_cat]    
    assert_equal 77, result[:second_cat]
    assert_equal 33, result[:no_category]    
    assert_equal nil,  result[:third_cat]        
    assert_equal nil,  result[:other]     

    # defined using the configurator
    result = OlapTest.olap_query(:category, :aggregate => :sum_int)
    assert_equal 33, result[:first_cat]    
    assert_equal 77, result[:second_cat]

    # using an SQL expression
    result = OlapTest.olap_query(:category, :aggregate => 'avg(olap_tests.int_field)')
    assert_equal 33.0, result[:first_cat]    
    assert_equal (33.0 + 44.0) / 2, result[:second_cat]
    assert_equal 33.0, result[:no_category]    
    assert_equal nil,  result[:third_cat]        
    assert_equal nil,  result[:other]
    
    # multiple aggregates
    result = OlapTest.olap_query(:category, :aggregate => { :records => :count_distinct, :avg => 'avg(olap_tests.int_field)', :sum_int => :sum_int })
    assert_equal 1, result.depth
    assert_equal 5, result.breadth

    assert_equal 1, result[:first_cat][:records]
    assert_equal 33.0, result[:first_cat][:sum_int]
    assert_equal (33.0 + 44.0) / 2, result[:second_cat][:avg]
    
    # array notation
    result = OlapTest.olap_query(:category, :aggregate => [:count_distinct, 'avg(olap_tests.int_field)', [:sum, :sum_int]] )
    assert_equal 1, result.depth
    assert_equal 5, result.breadth

    assert_equal 1, result[:first_cat][:count_distinct]
    assert_equal 33.0, result[:first_cat][:sum]
    assert_equal (33.0 + 44.0) / 2, result[:second_cat]['avg(olap_tests.int_field)']
  end

  def test_with_overlap
    result = OlapTest.olap_query(:with_overlap, :aggregate => :count_with_overlap)
    assert_kind_of ActiveRecord::OLAP::Cube, result    
    assert_equal 1, result.depth
    assert_equal 3, result.breadth
    
    assert_equal 2, result[:like_23]
    assert_equal 3, result[:starts_with_1]
    assert_equal 1, result[:other]
        
    assert result.sum > OlapTest.count
  end
  
  def test_conditions
    result = OlapTest.olap_query(:field => :category_field, :conditions => {:datetime_field => nil})
    assert_equal 1, result.depth
    assert_equal 2, result.sum
    
    assert_equal 1, OlapTest.olap_drilldown({:field => :category_field, :conditions => {:datetime_field => nil}} => 'second_cat').count
  end
  
  def test_config_with_lambda_trend_and_transpose
    
    result = OlapTest.olap_query(:category, :my_trend)
    assert_equal 5, result.breadth # 4 + other
    assert_equal 2, result.depth
    assert_equal :first_cat, result.dimension.categories.first.label
    
    # switch the dimensions using transpose
    result = result.transpose
    
    assert_equal 20, result.breadth # 20 periods
    assert_equal 2, result.depth
    
  end  
  
  def test_with_config
    result = OlapTest.olap_query(:category)
    assert_equal 1,   result[:first_cat]
    assert_equal 2,   result[:second_cat]
    assert_equal 0,   result[:third_cat]
    assert_equal nil, result[:fourth_cat]
    assert_equal 1,   result[:no_category]
  end
  
  
  def test_with_periods
    dimension_1 = { :trend => { :timestamp_field => :datetime_field, :period_count => 5}}
    dimension_2 = :category_field
  
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result.depth
    
    assert_equal 1, result[:period_3, 'first_cat']
    assert_equal 0, result[:period_3, 'second_cat']        
    assert_equal 0, result[:period_1, 'first_cat']        
    assert_equal 1, result[:period_1, 'second_cat']    
    assert_equal 0, result[:period_0, 'second_cat']
    assert_equal 0, result[:period_2, 'first_cat']            
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1 => :period_4, dimension_2 => 'second_cat').count
  end
  
  def test_with_three_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field   
    dimension_3 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2, dimension_3)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 3, result.depth
    
    # check that every value is set
    assert_equal 1, result[:datetime_field_set, 'first_cat',:string_like_2]
    assert_equal 0, result[:datetime_field_set, 'first_cat',:other]
    assert_equal 0, result[:datetime_field_set, 'second_cat',:string_like_2]
    assert_equal 1, result[:datetime_field_set, 'second_cat',:other]
    assert_equal 0, result[:datetime_field_set, nil,:string_like_2]
    assert_equal 0, result[:datetime_field_set, nil,:other]
    assert_equal 0, result[:other, 'first_cat',:string_like_2]
    assert_equal 0, result[:other, 'first_cat',:other]
    assert_equal 1, result[:other, 'second_cat',:string_like_2]
    assert_equal 0, result[:other, 'second_cat',:other]    
    assert_equal 1, result[:other, nil,:string_like_2]
    assert_equal 0, result[:other, nil,:other]    
    
    intermediate_result = result[:other]
    assert_kind_of ActiveRecord::OLAP::Cube, intermediate_result
    assert_equal 2, intermediate_result.depth
    assert_kind_of ActiveRecord::OLAP::Cube, result[:other, 'second_cat']
    assert_kind_of ActiveRecord::OLAP::Cube, result[:other]['second_cat']
    assert 1, intermediate_result['second_cat'][:string_like_2]
    assert 1, result[:other, 'second_cat'][:string_like_2]    
    
    found_categories = []
    intermediate_result.each do |category, res|
      assert_kind_of ActiveRecord::OLAP::Cube, res
      found_categories << category.label
    end
    assert_equal ['first_cat', 'second_cat', nil], found_categories
  end
  
  def test_condition_field_with_two_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field
  
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result.depth
  
    assert_equal 1, result[:datetime_field_set, 'first_cat']
    assert_equal 1, result[:datetime_field_set, 'second_cat']
    assert_equal 0, result[:datetime_field_set, nil]    
    assert_equal 0, result[:other, 'first_cat']    
    assert_equal 1, result[:other, 'second_cat']    
    assert_equal 1, result[:other, nil]
  
    result = OlapTest.olap_query(dimension_2, dimension_1)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result.depth
  
    assert_equal 1, result['first_cat', :datetime_field_set]
    assert_equal 1, result['second_cat', :datetime_field_set]
    assert_equal 1, result['second_cat', :other]
    assert_equal 1, result[nil, :other]
  end
  
  def test_condition_field
    result = OlapTest.olap_query(:category_field)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 1, result.depth
    
    assert_equal 1,   result['first_cat']
    assert_equal 2,   result['second_cat']
    assert_equal nil, result['third_cat']    
    assert_equal nil, result['fourth_cat']
    assert_equal 1,   result[nil]    
    
    assert_equal 1, OlapTest.olap_drilldown(:category_field => nil).count
  end
  
  def test_two_dimensions
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil} } }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result.depth
    
    assert_equal 0, result[:datetime_field_not_set,:other]
    assert_equal 2, result[:datetime_field_not_set,:string_like_2]    
    assert_equal 1, result[:other,:other]
    assert_equal 1, result[:other,:string_like_2]    
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1 => :datetime_field_not_set, dimension_2 => :other).length
    assert_equal 2, OlapTest.olap_drilldown(dimension_1 => :datetime_field_not_set, dimension_2 => :string_like_2).length
        
  end
  
  def test_two_dimensions_without_other
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil }, :other => false} }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'], :other => false } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result.depth
    
    assert_nil result[:other]
    assert_nil result[:datetime_field_not_set,:other]
    assert_equal 2, result[:datetime_field_not_set,:string_like_2]
    
  end  
  
  def test_olap_query
    result = OlapTest.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 2, result[:datetime_field_not_set]
    assert_equal 2, result[:other]
    
    result = OlapTest.olap_query :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] }
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 3, result[:string_like_2]
    assert_equal 1, result[:other]    
    
    found_categories = []
    result.each do |category, res|
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
    result = OlapTest.int_field_33.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_kind_of ActiveRecord::OLAP::Cube, result
    assert_equal 1, result[:datetime_field_not_set]
    assert_equal 2, result[:other]   # the other record does not fall within the scope int_field_33
      
    unsets = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :datetime_field_not_set)
    assert_equal 1, unsets.length
  
    others = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}} => :other)
    assert_equal 2, others.length    
  end
  
  # the actual SQL expression strings are connection specific,
  # For this test, they are in SQLite3 format
  def test_other_condition
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, :categories => { :datetime_field_set => {:datetime_field => nil}})
    assert_kind_of ActiveRecord::OLAP::Dimension, dimension
    assert_equal '((("olap_tests"."datetime_field" IS NULL)) IS NULL OR NOT(("olap_tests"."datetime_field" IS NULL)))', dimension[:other].to_sanitized_sql
    
    dimension = { :categories => { :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_kind_of String, dimension[:other].conditions
    
    dimension = { :categories => { :other => false, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => nil, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => ['willem = ?', "grea't"], :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_equal ["willem = ?", "grea't"], dimension[:other].conditions
    assert_equal "willem = 'grea''t'", dimension[:other].to_sanitized_sql
  end
end