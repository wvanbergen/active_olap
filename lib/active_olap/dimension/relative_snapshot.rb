class ActiveOLAP::Dimension::RelativeSnapshot < ActiveOLAP::Dimension

  attr_accessor :lower_bound, :upper_bound, :timestamp, :other, :include_future
  
  def has_overlap?
    true
  end

  def each_drilldown_value(options = {}, &block)
    (1..12).each do |index|
      yield(:index => index, :period_length => :month)
    end
  end

  def drilldown_value_expression(options = {}, variables = {})
    variables[:index]
  end
  
  def drilldown_filter_expression(options = {}, variables = {})
    reference_timestamp = interval(timestamp, variables[:index], variables[:period_length])
    
    conditions = [ "#{lower_bound} IS NULL OR #{lower_bound} <= #{reference_timestamp}",
                   "#{upper_bound} IS NULL OR #{upper_bound} >  #{reference_timestamp}" ]
    conditions << "#{now} >= #{reference_timestamp}" unless include_future
    conditions << other.gsub(':timestamp', reference_timestamp) if other
    conditions
  end
  
  def filter_expression(options, values = nil, variables = {})
    raise if values.nil?
    values.to_a.map do |value|
      drilldown_filter_expression(options, :period_length => :month, :index => value.to_i)
    end
  end
  
  def now
    return case ActiveOLAP.connection
      when DataObjects::Mysql::Connection
        "NOW()"
      when DataObjects::Sqlite3::Connection
        "datetime('now')"
      else
        raise "This DataObjects adapter (#{ActiveOLAP.connection.inspect}) is not yet supported!"
    end
  end
  
  def interval(timestamp, amount, period_size)
    return case ActiveOLAP.connection
      when DataObjects::Mysql::Connection
        "#{timestamp} + INTERVAL #{amount} #{period_size.to_s.upcase}"
      when DataObjects::Sqlite3::Connection
        "datetime(#{timestamp}, '#{amount} #{period_size}')"
      else
        raise "This DataObjects adapter (#{ActiveOLAP.connection.inspect}) is not yet supported!"
    end
  end
  
end
