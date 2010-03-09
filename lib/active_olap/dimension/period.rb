class ActiveOLAP::Dimension::Period < ActiveOLAP::Dimension
  
  attr_accessor :timestamp

  def initialize(variable, timestamp)
    super(variable)
    @timestamp = timestamp
  end

  def drilldown_value_expression(options = {}, variables = {})
    "DATE_FORMAT(#{timestamp}, '%Y-%m')"
  end

end
