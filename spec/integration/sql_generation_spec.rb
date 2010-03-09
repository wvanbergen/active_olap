require 'spec_helper'

describe ActiveOLAP, 'SQL generation' do

  it "should generate SQL correctly" do
    
    invoice_query       = ActiveOLAP::Query.new("invoices", "shop_id IS NOT NULL")
    timestamp_dimension = ActiveOLAP::Dimension::Period.new('creation_period', 'created_on')
    status_dimension    = ActiveOLAP::Dimension::Field.new('status')
    shop_count          = ActiveOLAP::Aggregate.count_distinct_shop_id
    total_revenue       = ActiveOLAP.aggregate('total_revenue', 'SUM(invoices.total_price)')
    
    invoice_query.drilldown_on(timestamp_dimension)
    invoice_query.drilldown_on(status_dimension)
    
    invoice_query.filter_on(status_dimension, ['success', 'pending'])
    
    invoice_query.calculate(total_revenue)
    invoice_query.calculate(shop_count)
    
    pre invoice_query.to_sql
  end
  
  it "should generate UNIONed SQL correctly" do
    subscription_query = ActiveOLAP::Query.new(
        'subscription_periods is LEFT JOIN subscription_periods rs ON (is.shop_id = rs.shop_id)',
        'is.initial_subscription = 1')

    snapshot_dimension = ActiveOLAP::Dimension::RelativeIntervalSnapshot.new(:snapshot_date, 
        :lower_bound => 'rs.started_at', :upper_bound => 'rs.ended_at', :timestamp => 'is.started_at')

    subscription_query.drilldown_on(snapshot_dimension)

    pre subscription_query.to_sql
  end
end
