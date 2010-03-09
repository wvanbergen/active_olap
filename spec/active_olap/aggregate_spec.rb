require 'spec_helper'

describe ActiveOLAP::Aggregate do
  
  describe '.method_missing' do
    it "should generate the correct SUM aggregate based on the method's name" do
      agg = ActiveOLAP::Aggregate.sum_field
      agg.variable.should == :sum_field
      agg.expression.should == "SUM(field)"
    end
    
    it "should generate a correct COUNT aggregate based on the method's name" do
      agg = ActiveOLAP::Aggregate.count_field_name
      agg.variable.should == :count_field_name
      agg.expression.should == "COUNT(field_name)"
    end
    
    it "should generate a correct COUNT DISTINCT aggregate based on the method's name" do
      agg = ActiveOLAP::Aggregate.count_distinct_field_name
      agg.variable.should == :count_distinct_field_name
      agg.expression.should == "COUNT(DISTINCT field_name)"
    end
  end
end
