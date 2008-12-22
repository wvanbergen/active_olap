module ActiveOLAP
  
  def enable_active_olap(config = nil, &block)

    self.send(:extend, ClassMethods)
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
    def olap_query(*args)

      # set aggregates apart if they are given
      aggregates_given = (args.last.kind_of?(Hash) && args.last.has_key?(:aggregate)) ? args.pop[:aggregate] : nil
      
      # parse the dimensions
      raise "You have to provide at least one dimension for an OLAP query" if args.length == 0    
      dimensions = args.collect { |d| Dimension.create(self, d) }
      
      raise "Overlapping categories only supported in the last dimension" if dimensions[0..-2].any? { |d| d.has_overlap? }
      raise "Only counting is supported with overlapping categories" if dimensions.last.has_overlap? && aggregates_given

      if !aggregates_given
        if dimensions.last.has_overlap?
          aggregates = []
        else
          aggregates = [Aggregate.create(self, :the_olap_count_field, :count_distinct)]
        end
      else 
        aggregates = Aggregate.all_from_olap_query_call(self, aggregates_given)        
      end

      conditions = self.send(:merge_conditions, *dimensions.map(&:conditions))
      joins = (dimensions.map(&:joins) + aggregates.map(&:joins)).flatten.uniq
      joins_clause = joins.empty? ? nil : self.send(:merge_joins, *joins)

      selects = aggregates.map { |agg| agg.to_sanitized_sql }
      groups  = []

      if aggregates.length > 0
        dimensions_to_group = dimensions.clone
      else 
        selects << dimensions.last.to_count_with_overlap_sql
        dimensions_to_group = dimensions[0, dimensions.length - 1]
      end
      
      dimensions_to_group.each_with_index do |d, index|
        var_name = "dimension_#{index}"
        groups  << self.connection.quote_column_name(var_name)
        selects << d.to_case_expression(var_name)
      end
    
      group_clause = groups.length > 0 ? groups.join(', ') : nil
      # TODO: having
      
      olap_temporarily_set_join_type if joins_clause
      
      query_result = self.scoped(:conditions => conditions).find(:all, :select => selects.join(', '), 
          :joins => joins_clause, :group => group_clause, :order => group_clause)  
      
      olap_temporarily_reset_join_type if joins_clause
      
      return Cube.new(self, dimensions, aggregates, query_result)
    end   
  end
  
  protected
  
  def olap_drilldown_finder_options(options)
    raise "You have to provide at least one dimension for an OLAP query" if options.length == 0    

    # returns an options hash to create a scope (the named_scope :olap_drilldown)
    conditions = options.map { |dim, cat| Dimension.create(self, dim).sanitized_sql_for(cat) }
    { :select => connection.quote_table_name(table_name) + '.*', :conditions => self.send(:merge_conditions, *conditions) }
  end
  
  # temporarily use LEFT JOINs for specified :joins
  def olap_temporarily_set_join_type
    ActiveRecord::Associations::ClassMethods::InnerJoinDependency::InnerJoinAssociation.send(:define_method, :join_type) { "LEFT OUTER JOIN" }
  end

  # reset to INNER JOINs after query has finished
  def olap_temporarily_reset_join_type
    ActiveRecord::Associations::ClassMethods::InnerJoinDependency::InnerJoinAssociation.send(:define_method, :join_type) { "INNER JOIN" }
  end
  
end


require 'active_olap/dimension'
require 'active_olap/category'
require 'active_olap/aggregate'
require 'active_olap/cube'
require 'active_olap/configurator'

require 'active_olap/helpers/display_helper'
require 'active_olap/helpers/table_helper'
require 'active_olap/helpers/chart_helper'
require 'active_olap/helpers/form_helper'

# inlcude the AcvtiveOLAP module in ActiveRecord::Base
ActiveRecord::Base.send(:extend, ActiveOLAP)