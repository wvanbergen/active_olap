require "#{File.dirname(__FILE__)}/helper"

require 'action_view'

class ActiveOLAP::HelperTest < Test::Unit::TestCase
  
  include ActiveOlapTestHelper
  
  # include some helper modules from ActionView
  include ActionView::Helpers::CaptureHelper
  include ActionView::Helpers::TagHelper

  # include the Active OLAP helper functions
  include ActiveOLAP::Helpers::TableHelper

  attr_accessor :output_buffer

  def setup
    create_db && create_corpus
  end

  def teardown
    cleanup_db
  end
  
  
  def test_1d_table
    cube = OlapTest.olap_query(:category_field)
    assert_active_olap_cube cube, [:unknown] 
    puts active_olap_table(cube)
    
    cube = OlapTest.olap_query(:with_overlap)
    assert_active_olap_cube cube, [:unknown]    
    puts active_olap_table(cube)
    
    cube = OlapTest.olap_query(:category_field, :aggregate => [:count_distinct, :avg_int_field])
    assert_active_olap_cube cube, [:unknown] 
    puts active_olap_table(cube)    
  end
  
  def test_2d_table
    cube = OlapTest.olap_query(:category_field, :my_trend)
    assert_active_olap_cube cube, 2
    
    table = active_olap_matrix(cube)
    puts table    
  end
  
  def test_multi_dimensional_table
    cube = OlapTest.olap_query(:category_field, :my_trend, :aggregate => [:count_distinct, :avg_int_field])
    assert_active_olap_cube cube, 2
    puts active_olap_table(cube)    
    
    cube = OlapTest.olap_query(:category_field, :with_overlap)
    assert_active_olap_cube cube, 2
    puts active_olap_table(cube)    
    
    cube = OlapTest.olap_query(:category_field, :my_trend, :with_overlap)
    assert_active_olap_cube cube, 3
    puts active_olap_table(cube)    
    
  end
  
  
end