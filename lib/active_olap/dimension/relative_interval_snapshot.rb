class ActiveOLAP::Dimension::RelativeIntervalSnapshot < ActiveOLAP::Dimension

  attr_accessor :lower_bound, :upper_bound, :timestamp, :other
  
  def has_overlap?
    true
  end

  def each_drilldown_value(options = {}, &block)
    (1..12).each do |index|
      yield(:period_index => index, :period_length => :month)
    end
  end

  def drilldown_value_expression(options = {}, variables = {})
    variables[:period_index]
  end
  
  def drilldown_filter_expression(options = {}, variables = {})
    # TODO: different per backend
    
    reference_timestamp = "#{timestamp} + INTERVAL #{variables[:period_index]} #{variables[:period_length].to_s.upcase}"
    [
      "#{lower_bound} IS NULL OR #{lower_bound} <= #{reference_timestamp}",
      "#{upper_bound} IS NULL OR #{upper_bound} >  #{reference_timestamp}",
      other
    ]
  end
  
end
