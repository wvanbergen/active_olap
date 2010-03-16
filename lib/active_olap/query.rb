class ActiveOLAP::Query


  attr_reader :body, :default_selection
  attr_reader :drilldowns, :filters, :aggregates
  
  def initialize(body, default_selection = nil)
    @body, @default_selection = body, default_selection
    
    @drilldowns = []
    @filters    = []
    @aggregates = []
  end
  
  def self.create(body, default_filter = nil)
    new(body, default_filter)
  end
  
  def drilldown_on(dimension, drilldown_options = {})
    drilldowns << ActiveOLAP::Drilldown.new(self, dimension, drilldown_options)
  end
  
  def filter_on(dimension, values, filter_options = {})
    filters << ActiveOLAP::Filter.new(self, dimension, values, filter_options)
  end
  
  def calculate(aggregate)
    aggregates << aggregate
  end
  
  # Generates the SQL statement for this query.
  def to_sql
    
    # See what drilldowns will require UNIONing multiple SELECT statements.
    drilldowns_requiring_unions = drilldowns.select { |dd| dd.requires_unions? }
    sql = case drilldowns_requiring_unions.size
      when 0 then generate_sql
      when 1 then generate_union_sql(drilldowns_requiring_unions.first)
      else raise "Multiple dimensions that require UNIONs in a single query are not supported!"
    end
    
    # Add the order by clause
    sql << "\n ORDER BY " << drilldowns.map(&:variable).join(', ') if drilldowns.any?
    
    return sql
  end

  alias :to_s :to_sql

  protected
  
  # generates multiple SELECT statements, and UNIONs them together
  def generate_union_sql(union_drilldown)
    sql_fragments = union_drilldown.each_value.map do |variables|
      generate_sql(variables)
    end
    sql_fragments.join("\n\nUNION\n\n")
  end
  
  # Generates a single SQL SELECT statement, without ORDER clause.
  def generate_sql(variables = {})
    
    projections  = ActiveSupport::OrderedHash.new
    selections   = [default_selection]
    group_bys    = []
    havings      = []
    
    drilldowns.each do |drilldown|
      projections[drilldown.variable] = drilldown.value_expression(variables)
      selections << drilldown.filter_expression(variables)
    end
    
    # aggregates << ActiveOLAP::Aggregate.count if aggregates.empty?
    aggregates.each { |agg| projections[agg.variable] = agg.expression }
    
    filters.each { |filter| selections << filter.expression(variables) }
    selections = selections.flatten.compact
    
    if projections.empty?
      projections_clause = '*'
    else
      projections_clause = projections.map { |name, expr| "#{format_select_sql(expr)} AS #{name}" }.join(",\n       ")
    end
    
    sql = "SELECT #{projections_clause}\n  FROM #{body}"
    sql << "\n WHERE (#{selections.join(")\n   AND (")})" if selections.any?
    sql << "\n GROUP BY #{drilldowns.map(&:variable).join(', ')}" if drilldowns.any?
    sql << "\n HAVING (#{havings.join(') AND (')})" if havings.any?
    sql
  end
  
  def format_select_sql(sql)
    sql.to_s.gsub(/\r?\n/, "\n       ")
  end
end
