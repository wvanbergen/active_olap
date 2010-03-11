class ActiveOLAP::Runner
  
  attr_reader :query, :sql, :duration, :result

  def initialize(query)
    @query = query
  end
  
  def perform
    @sql = query.to_sql
    @duration = Benchmark.realtime { @raw_result = ActiveOLAP.connection.create_command(@sql).execute_reader }
    return @raw_result
  end
end
