require 'active_support'
require 'data_objects'
require 'benchmark'

module ActiveOLAP
  extend self
  
  attr_accessor :connection
  
  # RESOLVING CONSTANTS
  
  def const_missing(const)
    load_missing_constant(self, const)
  end
  
  def load_missing_constant(namespace, const)
    require "#{namespace}::#{const}".underscore
    namespace.const_get(const)
  end
  
  # RUNNING QUERIES
  
  def execute(query)
    ActiveOLAP::Runner.new(query).perform
  end
  
  # CONSTRUCTORS
  
  def query(*args)
    ActiveOLAP::Query.create(*args)
  end
  
  def aggregate(*args)
    ActiveOLAP::Aggregate.create(*args)
  end
  
  def dimension(*args)
    ActiveOLAP::Dimension.create(*args)
  end
end
