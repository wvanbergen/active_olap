require "#{File.dirname(__FILE__)}/test_helper"

class OlapTest < ActiveRecord::Base  
  named_scope :int_field_33, :conditions => {:int_field => 33}
  
  enable_active_olap
  
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


  def test_with_periods
    dimension_1 = { :trend => { :timestamp_field => :datetime_field, :period_count => 5}}
    dimension_2 = :category_field
  
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result.depth
    
    assert_equal 1, result[:period_4]['first_cat']
    assert_equal 0, result[:period_4]['second_cat']        
    assert_equal 0, result[:period_2]['first_cat']        
    assert_equal 1, result[:period_2]['second_cat']    
    assert_equal 0, result[:period_1]['second_cat']
    assert_equal 0, result[:period_3]['first_cat']            
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1, :period_4, dimension_2, 'second_cat').count
  end

  def test_with_three_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field   
    dimension_3 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2, dimension_3)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 3, result.depth
    
    # check that every value is set
    assert_equal 1, result[:datetime_field_set]['first_cat'][:string_like_2]
    assert_equal 0, result[:datetime_field_set]['first_cat'][:other]
    assert_equal 0, result[:datetime_field_set]['second_cat'][:string_like_2]
    assert_equal 1, result[:datetime_field_set]['second_cat'][:other]
    assert_equal 0, result[:datetime_field_set][nil][:string_like_2]
    assert_equal 0, result[:datetime_field_set][nil][:other]
    assert_equal 0, result[:other]['first_cat'][:string_like_2]
    assert_equal 0, result[:other]['first_cat'][:other]
    assert_equal 1, result[:other]['second_cat'][:string_like_2]
    assert_equal 0, result[:other]['second_cat'][:other]    
    assert_equal 1, result[:other][nil][:string_like_2]
    assert_equal 0, result[:other][nil][:other]    
  end
  
  def test_condition_field_with_two_dimensions
    dimension_1 = { :categories => { :datetime_field_set => 'datetime_field IS NOT NULL' } }
    dimension_2 = :category_field
  
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result.depth
    
    assert_equal 1, result[:datetime_field_set]['first_cat']
    assert_equal 1, result[:datetime_field_set]['second_cat']
    assert_equal 1, result[:other]['second_cat']    
    assert_equal 1, result[:other][nil]
    
    result = OlapTest.olap_query(dimension_2, dimension_1)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result.depth
  
    assert_equal 1, result['first_cat'][:datetime_field_set]
    assert_equal 1, result['second_cat'][:datetime_field_set]
    assert_equal 1, result['second_cat'][:other]
    assert_equal 1, result[nil][:other]
  end
  
  def test_condition_field
    dimension = :category_field
    result = OlapTest.olap_query(dimension)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 1, result.depth
    
    assert_equal 1,   result['first_cat']
    assert_equal 2,   result['second_cat']
    assert_equal nil, result['third_cat']    
    assert_equal nil, result['fourth_cat']
    assert_equal 1,   result[nil]    
    
    assert_equal 1, OlapTest.olap_drilldown(dimension, nil).count
  end
  
  def test_two_dimensions
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil} } }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result.depth
    
    assert_equal 0, result[:datetime_field_not_set][:other]
    assert_equal 2, result[:datetime_field_not_set][:string_like_2]    
    assert_equal 1, result[:other][:other]
    assert_equal 1, result[:other][:string_like_2]    
    
    assert_equal 0, OlapTest.olap_drilldown(dimension_1, :datetime_field_not_set, dimension_2, :other).length
    assert_equal 2, OlapTest.olap_drilldown(dimension_1, :datetime_field_not_set, dimension_2, :string_like_2).length
        
  end
  
  def test_two_dimensions_without_other
    dimension_1 = { :categories => { :datetime_field_not_set => {:datetime_field => nil }, :other => false} }
    dimension_2 = { :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'], :other => false } }
    
    result = OlapTest.olap_query(dimension_1, dimension_2)
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result.depth
    
    assert_nil result[:other]
    assert_nil result[:datetime_field_not_set][:other]
    assert_equal 2, result[:datetime_field_not_set][:string_like_2]
    
  end  
  
  def test_olap_query
    result = OlapTest.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 2, result[:datetime_field_not_set]
    assert_equal 2, result[:other]
    
    result = OlapTest.olap_query :categories => { :string_like_2 => ["string_field LIKE ?", '%2%'] }
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 3, result[:string_like_2]
    assert_equal 1, result[:other]    
  end
  
  def test_drilldown
    unsets = OlapTest.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}}, :datetime_field_not_set)
    assert_equal 2, unsets.length
  
    others = OlapTest.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}}, :other)
    assert_equal 2, others.length  
  end
   
  def test_olap_query_within_scope
    assert_equal 3, OlapTest.int_field_33.count
    result = OlapTest.int_field_33.olap_query :categories => { :datetime_field_not_set => {:datetime_field => nil} }
    assert_kind_of ActiveRecord::OLAP::QueryResult, result
    assert_equal 1, result[:datetime_field_not_set]
    assert_equal 2, result[:other]   # the other record does not fall within the scope int_field_33
      
    unsets = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}}, :datetime_field_not_set)
    assert_equal 1, unsets.length
  
    others = OlapTest.int_field_33.olap_drilldown({:categories => {:datetime_field_not_set => {:datetime_field => nil}}}, :other)
    assert_equal 2, others.length    
  end
  
  # the actual SQL expression strings are connection specific,
  # For this test, they are in SQLite3 format
  def test_other_condition
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, :categories => { :datetime_field_set => {:datetime_field => nil}})
    assert_kind_of ActiveRecord::OLAP::Dimension, dimension
    assert_equal '((("olap_tests"."datetime_field" IS NULL)) IS NULL OR NOT(("olap_tests"."datetime_field" IS NULL)))', dimension[:other][:expression]
    
    dimension = { :categories => { :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_kind_of String, dimension[:other][:expression]
    
    dimension = { :categories => { :other => false, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => nil, :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_nil dimension[:other]
    
    dimension = { :categories => { :other => ['willem = ?', 'great'], :datetime_field_set => {:datetime_field => nil} } }
    dimension = ActiveRecord::OLAP::Dimension.create(OlapTest, dimension)
    assert_kind_of Array, dimension[:other][:expression]
    assert_equal ["willem = ?", 'great'], dimension[:other][:expression]
  end
end