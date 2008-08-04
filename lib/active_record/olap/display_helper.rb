module ActiveRecord::Olap::DisplayHelper
  

  def show_category(dimension, category, options = {})
    return category.info[:name] unless category.info[:name].blank?
    return show_period(dimension, category) if dimension.is_time_dimension?
    return category.to_s.humanize if category.label.kind_of?(Symbol)
    return category.to_s 
  end
  
  def show_period(dimension, category, options = {})
    options[:chart] ? "#{category.info[:end].strftime('\'%y/%m/%d')}" : "#{category.info[:begin].strftime('\'%y/%m/%d')} - #{category.info[:end].strftime('\'%y/%m/%d')}"
  end

  
  
end