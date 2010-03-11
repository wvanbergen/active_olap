class Invoice
  
  include DataMapper::Resource
  
  property :id,          Serial
  property :account_id,  Integer
  property :created_on,  Date
  property :total_price, BigDecimal, :scale => 2, :precision => 10
  property :status,      String
  property :bill_on,     Date
end

class SubscriptionPeriod
  include DataMapper::Resource
  
  property :id,                   Serial
  property :account_id,           Integer
  property :plan_name,            String
  property :initial_subscription, Boolean
  property :started_at,           DateTime
  property :ended_at,             DateTime
end
