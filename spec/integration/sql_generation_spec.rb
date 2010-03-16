require 'spec_helper'

describe ActiveOLAP, 'SQL generation' do

  it "should generate SQL correctly" do
    
    invoice_query       = ActiveOLAP::Query.create("invoices", "account_id IS NOT NULL")
    timestamp_dimension = ActiveOLAP::Dimension::Period.create('creation_period', 'created_on')
    status_dimension    = ActiveOLAP::Dimension::Expression.create('status')
    shop_count          = ActiveOLAP::Aggregate.count_distinct(:account_id)
    total_revenue       = ActiveOLAP.aggregate('total_revenue', 'SUM(invoices.total_price)')
    
    invoice_query.drilldown_on(timestamp_dimension)
    invoice_query.drilldown_on(status_dimension)
    
    invoice_query.filter_on(status_dimension, ['success', 'pending'])
    
    invoice_query.calculate(total_revenue)
    invoice_query.calculate(shop_count)

    pre invoice_query.to_sql
    result = ActiveOLAP.execute(invoice_query)

  end
  
  it "should generate UNIONed SQL correctly for snapshot dimensions" do
    accounts_receivable = ActiveOLAP.query("invoices", "account_id IS NOT NULL")
    balance_date  = ActiveOLAP::Dimension::Snapshot.create(:balance_date, 
                         :lower_bound => :created_on, :upper_bound => :bill_on)
    total_revenue = ActiveOLAP.aggregate(:total_revenue, 'SUM(total_price)')
    
    accounts_receivable.drilldown_on(balance_date)
    accounts_receivable.calculate(total_revenue)
    
    pre accounts_receivable.to_sql
    result = ActiveOLAP.execute(accounts_receivable)
  end
  
  it "should generate UNIONed SQL correctly for relative snapshot dimensions" do
    subscription_query = ActiveOLAP::Query.create(
        'subscription_periods is LEFT JOIN subscription_periods rs ON (is.account_id = rs.account_id)',
        'is.initial_subscription = 1')

    snapshot_dimension = ActiveOLAP::Dimension::RelativeSnapshot.create(:snapshot_date, 
        :lower_bound => 'rs.started_at', :upper_bound => 'rs.ended_at', :timestamp => 'is.started_at')

    subscription_query.drilldown_on(snapshot_dimension)

    pre subscription_query.to_sql
  end

end
