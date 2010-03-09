class ActiveOLAP::Filter
  
  attr_accessor :query, :dimension, :options
  
  def initialize(query, dimension, options = {})
    @query, @dimension, @options = query, dimension, options
  end
  
  def expression(variables = {})
    dimension.filter_expression(options, variables)
  end
  
end
