class ActiveOLAP::Drilldown
  
  attr_accessor :query, :dimension, :options
  
  def initialize(query, dimension, options = {})
    @query, @dimension, @options = query, dimension, options
  end
  
  def variable
    dimension.variable
  end
  
  def values
    dimension.values(options)
  end
  
  def each_value
    if block_given?
      dimension.each_drilldown_value(options) do |variables|
        yield(variables)
      end
    else
      Enumerable::Enumerator.new(dimension, :each_drilldown_value)
    end
  end
  
  def requires_unions?
    dimension.has_overlap?
  end
  
  def value_expression(variables = {})
    dimension.drilldown_value_expression(options, variables)
  end
  
  def filter_expression(variables = {})
    dimension.drilldown_filter_expression(options, variables)
  end
end
