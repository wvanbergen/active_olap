class ActiveOLAP::Cube
  
  attr_reader :query, :raw_result
  
  def initialize(query, raw_result)
    @query, @raw_result = query, raw_result
  end
  
  def drilldown_fields
    @raw_result.fields.slice(0, @query.drilldowns.size)
  end
  
  def aggregate_fields
    @raw_result.fields.slice(0 - @query.aggregates.size, @query.aggregates.size)
  end
end
