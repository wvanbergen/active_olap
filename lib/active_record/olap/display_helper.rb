module ActiveRecord::Olap::DisplayHelper
  

  def show_active_olap_category(category, options = {})
    return category.info[:name] unless category.info[:name].blank?
    return show_active_olap_period(category, options) if category.dimension.is_time_dimension?
    return category.to_s.humanize if category.label.kind_of?(Symbol)
    return category.to_s 
  end
  
  def show_active_olap_period(category, options = {})
    options[:for] && [:line_chart].include?(options[:for])
            ? "#{category.info[:end].strftime('\'%y/%m/%d')}" 
            : "#{category.info[:begin].strftime('\'%y/%m/%d')} - #{category.info[:end].strftime('\'%y/%m/%d')}"
  end


  def show_active_olap_aggregate(aggregate, options = {})
    aggregate.info[:name].blank? ? aggregate.label.to_s : aggregate.info[:name]
  end
  
  def show_active_olap_value(category, aggregate, value, options = {})
    value.nil? ? '-' : value.to_s
  end

  def show_active_olap_dimension(dimension, options = {})
    return dimension.info[:name] unless dimension.info[:name].blank?    
    "dimension"
  end
  
  def show_active_olap_cube(cube, options = {})
    return cube.info[:name] unless cube.info[:name].blank?
    "OLAP cube"
  end
  
end