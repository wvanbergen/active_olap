class ActiveOLAP::Dimension::Snapshot < ActiveOLAP::Dimension
  
  attr_accessor :lower_bound, :upper_bound, :other

  def has_overlap?
    true
  end
  
  # def timestamp_series(options = {})
  #   dates = [current_date = Date.today.beginning_of_month >> 1]
  #   24.times do |i|
  #     current_date = current_date << 1
  #     dates.unshift(current_date)
  #   end
  #   dates
  # end
  
  def each_drilldown_value(options = {}, &block)
    snapshots = (options[:snapshots] || 12).to_i
    timestamp = Date.today.beginning_of_month # FIXME
    timestamp = timestamp << snapshots # FIXME
    (1..snapshots).each do |index|
      timestamp = timestamp >> 1 # FIXME
      yield(:timestamp => timestamp) # FIXME
    end
  end

  def drilldown_value_expression(options = {}, variables = {})
    "'#{variables[:timestamp].to_s(:db)}'"
  end
  
  def drilldown_filter_expression(options = {}, variables = {})
    conditions = [ "#{lower_bound} IS NULL OR #{lower_bound} <= '#{variables[:timestamp].to_s(:db)}'",
                   "#{upper_bound} IS NULL OR #{upper_bound} >  '#{variables[:timestamp].to_s(:db)}'" ]
    conditions << merge_bindings(other, variables) unless other.nil?
  end
  
  def filter_expression(options, values = nil, variables = {})
    raise if values.nil?
    values.map do |value|
      drilldown_filter_expression(options, variables => { :timestamp => Date.parse(value) })
    end
  end
  
  def merge_bindings(sql, bindings = {})
    sql.gsub(/\:\w+/) do |binding_name|
      "'#{bindings[binding_name[1..-1].to_sym]}'"
    end
  end
end
