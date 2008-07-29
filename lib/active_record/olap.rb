module ActiveRecord::OLAP
  
  def enable_active_olap
    self.class_eval { extend ClassMethods }
    self.named_scope :olap_drilldown, lambda { |*args| self.olap_drilldown_finder_options(args) }
  end
  
  
  module ClassMethods
    
    # Performs an OLAP query that counts how many records do occur in given categories.
    # It can be used for multiple dimensions 
    # It expects a list of category definitions
    def olap_query(*dimensions)
      raise "You have to provide at least one dimension for an OLAP query" if dimensions.length == 0    
      dimensions = dimensions.collect { |d| Dimension.create(self, d) }

      selects = []
      groups  = []

      unless dimensions.last.is_field_dimension?
        selects << dimensions.last.to_aggregate_expression
        dimensions_to_group = dimensions[0, dimensions.length - 1]
      else 
        # is this a good constant expression?
        selects << "COUNT(DISTINCT #{connection.quote_table_name(table_name)}.id) AS the_olap_count_field"
        dimensions_to_group = dimensions.clone
      end
      
      dimensions_to_group.each_with_index do |d, index|
        var_name = "dimension_#{index}"
        groups  << self.connection.quote_column_name(var_name)
        selects << d.to_group_expression(var_name)
      end
      
      group_clause = groups.length > 0 ? groups.join(', ') : nil
      query_result = self.find(:all, :select => selects.join(', '), :group => group_clause, :order => group_clause)  

      return QueryResult.new(self, dimensions, query_result)
    end   
  end
  
  protected
  
  def olap_drilldown_finder_options(dimension_and_categories)
    raise "You have to provide at least one dimension for an OLAP query" if dimension_and_categories.length == 0    
    raise "You must provide pairs (the dimension and the category to drilldown to)" unless dimension_and_categories.length % 2 == 0

    dim = nil
    conditions = []
    dimension_and_categories.each do |dim_or_cat|
      if dim.nil?
        dim = Dimension.create(self, dim_or_cat)
      else
        conditions << dim.sanitized_sql_for(dim_or_cat)
        dim = nil
      end
    end
    
    # returns an options hash to create a scope (the named_scope :olap_drilldown)
    { :select => connection.quote_table_name(table_name) + '.*', :conditions => conditions.join(' AND ') }
 
  end
  
end