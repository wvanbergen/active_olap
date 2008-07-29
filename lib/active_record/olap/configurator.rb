module ActiveRecord::OLAP
  
  class Configurator
    
    # initializes a OLAP::Configurator object, which is used in the block 
    # passed to the call enable_active_olap. It can be used to register
    # dimensions and classes
    def initialize(klass)
      @klass = klass
    end
    
    # registers a dimension for the class it belongs to
    def dimension(name, definition = nil)
      definition = name.to_sym if definition.nil?
      @klass.active_olap_dimensions[name] = definition
    end
    
    # registers an aggregate for the class it belongs to
    def aggregate(name, definition)
      @klass.active_olap_aggregates[name] = definition
    end
  end
end