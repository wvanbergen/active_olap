require 'spec_helper'

describe ActiveOLAP, 'query results' do
  
  it "should execute the SQL query correctly" do
    invoice_query       = ActiveOLAP::Query.create("invoices")
    timestamp_dimension = ActiveOLAP::Dimension::Period.create('creation_period', 'created_on')
    
    invoice_query.drilldown_on(timestamp_dimension)
    result = ActiveOLAP.execute(invoice_query)
  end
end
