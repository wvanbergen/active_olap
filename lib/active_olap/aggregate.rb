class ActiveOLAP::Aggregate
  
  attr_reader :variable, :expression
  
  def initialize(variable, expression)
    @variable, @expression = variable, expression
  end
  
  def self.create(variable, expression)
    new(variable, expression)
  end
  
  def self.count(value = '*')
    new("count_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "COUNT(#{value})")
  end

  def self.count_distinct(value = '*')
    new("count_distinct_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "COUNT(DISTINCT #{value})")
  end
  
  def self.sum(value)
    new("sum_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "SUM(#{value})")
  end

  def self.avg(value)
    new("avg_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "AVG(#{value})")
  end

  def self.min(value)
    new("min_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "MIN(#{value})")
  end

  def self.max(value)
    new("max_#{value.to_s.gsub(/\W+/, '_')}".sub(/_+$/, '').to_sym, "MAX(#{value})")
  end

  
  # Creates aggregate functions based on the method's name
  def self.method_missing(method, *args)
    case method.to_s
      when /^count_distinct_(\w+)/i then new(method, "COUNT(DISTINCT #{$1})")
      when /^(sum|avg|count|stdev|min|max|variance)_(\w+)/i then new(method, "#{$1.upcase}(#{$2})")
      else super(method, args)
    end
  end
end
