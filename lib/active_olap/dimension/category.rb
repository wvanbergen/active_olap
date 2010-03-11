class ActiveOLAP::Dimension::Category < ActiveOLAP::Dimension
  
  attr_accessor :values
  attr_accessor :else_value
  
  def drilldown_value_expression(options = {}, variables = {})
    case_statement(values, else_values)
  end


end
