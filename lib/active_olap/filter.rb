class ActiveOLAP::Filter
  
  attr_accessor :query, :dimension, :options, :values
  
  def initialize(query, dimension, values = nil, options = {})
    @query, @dimension, @values, @options = query, dimension, values, options
  end
  
  def expression(variables = {})
    dimension.filter_expression(options, values, variables)
  end
  
end
