class ActiveOLAP::Dimension::Expression < ActiveOLAP::Dimension
  
  attr_accessor :expression
  
  def initialize(variable, expression = nil)
    super(variable)
    @expression = expression || variable
  end
  
  def drilldown_value_expression(options = {}, variables = {})
    expression.to_s
  end
  
  # def filter_expression(options = {}, variables = {})
  #   values = case options
  #     when Hash  then options[:values]
  #     when Array then options
  #     else [options]
  #   end
  #   
  #   "#{expression} IN ('#{values.join("', '")}')"
  # end
end
