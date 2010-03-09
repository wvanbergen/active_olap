require 'active_support'
require 'data_objects'

module ActiveOLAP
  
  def self.const_missing(const)
    load_missing_constant(self, const)
  end
  
  def self.load_missing_constant(namespace, const)
    require "#{namespace}::#{const}".underscore
    namespace.const_get(const)
  end
  
  def self.query(*args)
    ActiveOLAP::Query.new(*args)
  end
  
  def self.aggregate(*args)
    ActiveOLAP::Aggregate.new(*args)
  end
  
  def self.dimension(type, variable, options = {})
    ActiveOLAP::Dimension.create(type, variable, options)
  end
end
