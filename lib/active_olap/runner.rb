class ActiveOLAP::Runner
  
  attr_reader :query, :sql, :duration

  def initialize(query)
    @query = query
  end
  
  def perform
    @sql = query.to_sql
    @duration = Benchmark.realtime { @raw_result = ActiveOLAP.connection.create_command(@sql).execute_reader }
    return ActiveOLAP::Cube.new(@query, @raw_result)
  end
end
