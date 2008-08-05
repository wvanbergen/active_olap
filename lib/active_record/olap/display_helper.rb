module ActiveRecord::Olap::DisplayHelper
  

  def show_active_olap_category(category, options = {})
    return category.info[:name] unless category.info[:name].blank?
    return show_active_olap_period(category) if category.dimension.is_time_dimension?
    return category.to_s.humanize if category.label.kind_of?(Symbol)
    return category.to_s 
  end
  
  def show_active_olap_period(category, options = {})
    options[:chart] ? "#{category.info[:end].strftime('\'%y/%m/%d')}" : "#{category.info[:begin].strftime('\'%y/%m/%d')} - #{category.info[:end].strftime('\'%y/%m/%d')}"
  end


  def show_active_olap_aggregate(aggregate, options = {})
    aggregate.info[:name].blank? ? aggregate.label.to_s : aggregate.info[:name]
  end
  
  def show_active_olap_value(category, aggregate, value, options = {})
    value.nil? ? '-' : value.to_s
  end

  
  
end