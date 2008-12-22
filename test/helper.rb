$:.reject! { |e| e.include? 'TextMate' }

require 'rubygems'
require 'test/unit'
require 'active_record'

require "#{File.dirname(__FILE__)}/../lib/active_olap"
require "#{File.dirname(__FILE__)}/../lib/active_olap/test/assertions"

module ActiveOlapTestHelper
  
  def self.included(base)
    base.send :include, ActiveOLAP::Test::Assertions
  end
  
  def create_db 
  
    ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

    ActiveRecord::Schema.define(:version => 1) do
      create_table :olap_tests do |t|
        t.string   :string_field
        t.integer  :int_field
        t.string   :category_field
        t.datetime :datetime_field
        t.timestamps
      end
    
      create_table :olap_associations do |t|
        t.integer  :olap_test_id
        t.string   :category
        t.float    :price
        t.timestamps
      end
    
    
    end
  end
  
  def create_corpus
    OlapTest.create!({ :string_field => '123', :int_field => 33, :category_field => 'first_cat',  :datetime_field => 2.day.ago })
    OlapTest.create!({ :string_field => '123', :int_field => 44, :category_field => 'second_cat', :datetime_field => nil })
    OlapTest.create!({ :string_field => '',    :int_field => 33, :category_field => 'second_cat', :datetime_field => 4.days.ago })    
    with_assocs = OlapTest.create!({ :string_field => '12',  :int_field => 33, :category_field => nil,  :datetime_field => nil })
    
    with_assocs.olap_associations.create!({:category => 'first',  :price => 1.2})
    with_assocs.olap_associations.create!({:category => 'first',  :price => 1.2})
    with_assocs.olap_associations.create!({:category => 'second', :price => 1.4})        
    with_assocs.olap_associations.create!({:category => 'second', :price => 0.7})
    with_assocs.olap_associations.create!({:category => nil,      :price => 0.7})
    with_assocs.olap_associations.create!({:category => 'third',  :price => 0.5})
  end
  
  def cleanup_db
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.drop_table(table)
    end 
  end
end

class OlapTest < ActiveRecord::Base  
  
  has_many :olap_associations
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
        
    olap.dimension :with_overlap, :overlap => true, :categories => {
          :starts_with_1 => "string_field LIKE '1%'",
          :like_23       => "string_field LIKE '%23%'"
        }
      
    olap.dimension :in_association, :overlap => true, :categories => {
          :first  => "olap_associations.category = 'first'",
          :second => "olap_associations.category = 'second'"          
        }, :joins => 'LEFT JOIN olap_associations ON olap_associations.olap_test_id = olap_tests.id'
        
    olap.aggregate :sum_int, :sum_int_field
    olap.aggregate :avg_int_field
    olap.aggregate :total_price, 'SUM(olap_associations.price)', :joins => 'LEFT JOIN olap_associations ON olap_associations.olap_test_id = olap_tests.id'
  end
  
end

class OlapAssociation < ActiveRecord::Base
  belongs_to :olap_test
end