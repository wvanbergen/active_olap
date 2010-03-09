class ActiveOLAP::Runner
  
  attr_reader :query, :sql, :result
  
  def initialize(query)
    @query = query
  end
  
  def run!
    @sql = query.to_sql
    
  end
end
