module ActiveRecord::OLAP
  
  def enable_active_olap(config = nil, &block)

    self.class_eval { extend ClassMethods }
    self.named_scope :olap_drilldown, lambda { |hash| self.olap_drilldown_finder_options(hash) }    
    
    self.cattr_accessor :active_olap_dimensions, :active_olap_aggregates
    self.active_olap_dimensions = {}
    self.active_olap_aggregates = {}    
    
    if config.nil? && block_given?
      conf = Configurator.new(self)
      yield(conf) 
    end
    
  end
  
  
  module ClassMethods
    
    # Performs an OLAP query that counts how many records do occur in given categories.
    # It can be used for multiple dimensions 
    # It expects a list of category definitions
    def olap_query(*dimensions)

      if dimensions.last.kind_of?(Hash) && dimensions.last.has_key?(:aggregate)
        aggregates = Aggregate.all_from_olap_query_call(self, dimensions.pop[:aggregate])
      else
        aggregates = [Aggregate.create(self, :the_olap_count_field, :count_distinct)]
      end
      
      raise "You have to provide at least one dimension for an OLAP query" if dimensions.length == 0    
      
      scope_conditions = []
      dimensions = dimensions.collect { |d| Dimension.create(self, d, scope_conditions) }
      conditions = self.send(:merge_conditions, *scope_conditions)

      selects = aggregates.map { |agg| agg.to_sanitized_sql }
      groups  = []

      if aggregates.length > 0
        dimensions_to_group = dimensions.clone
      else 
        selects << dimensions.last.to_aggregate_expression
        dimensions_to_group = dimensions[0, dimensions.length - 1]
      end
      
      dimensions_to_group.each_with_index do |d, index|
        var_name = "dimension_#{index}"
        groups  << self.connection.quote_column_name(var_name)
        selects << d.to_group_expression(var_name)
      end
    
      group_clause = groups.length > 0 ? groups.join(', ') : nil
      # TODO: joins, having
      query_result = self.scoped(:conditions => conditions).find(:all, :select => selects.join(', '), :group => group_clause, :order => group_clause)  

      return Cube.new(self, dimensions, aggregates, query_result)
    end   
  end
  
  protected
  
  def olap_drilldown_finder_options(options)
    raise "You have to provide at least one dimension for an OLAP query" if options.length == 0    

    # returns an options hash to create a scope (the named_scope :olap_drilldown)
    scope_conditions = []
    scope_conditions += options.map { |dim, cat| Dimension.create(self, dim, scope_conditions).sanitized_sql_for(cat) }
    conditions = self.send(:merge_conditions, *scope_conditions)
    return { :select => connection.quote_table_name(table_name) + '.*', :conditions => conditions }
  end
  
end