class ActiveOLAP::Dimension::Period < ActiveOLAP::Dimension
  
  attr_accessor :timestamp

  def initialize(variable, timestamp)
    super(variable)
    @timestamp = timestamp
  end

  
  def value_expressions(options = {})
    expressions = ActiveSupport::OrderedHash.new
    timestamp_series(options).each_cons(2) do |(begin_date, end_date)|
      sql = "#{timestamp} >= '#{begin_date.to_s(:db)}' AND #{timestamp} < '#{end_date.to_s(:db)}'"
      expressions[begin_date.strftime('%Y-%m')] = sql
    end
    expressions
  end


  def timestamp_series(options = {})
    dates = [current_date = Date.today.beginning_of_month >> 1]
    24.times do |i|
      current_date = current_date << 1
      dates.unshift(current_date)
    end
    dates
  end

  def drilldown_value_expression(options = {}, variables = {})
    case_statement(value_expressions(options))
  end
  
  def drilldown_filter_expression(options = {}, variables = {})
    timestamps = timestamp_series(options)
    ["#{timestamp} >= '#{timestamps.first.to_s(:db)}'", "#{timestamp} <  '#{timestamps.last.to_s(:db)}'"]
  end

end
