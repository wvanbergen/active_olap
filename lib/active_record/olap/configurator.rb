module ActiveRecord::OLAP
  
  class Configurator
    
    def initialize(klass)
      @klass = klass
    end
    
    def dimension(name, definition)
      @klass.active_olap_dimensions[name] = definition
      
    end
    
    def aggregate(name, definition)
      @klass.active_olap_aggregates[name] = definition
    end
  end
end