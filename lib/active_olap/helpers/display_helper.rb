module ActiveOLAP::Helpers
  module DisplayHelper
  

    def show_active_olap_category(category, options = {})
      return category.info[:name] unless category.info[:name].blank?
      return show_active_olap_period(category, options) if category.dimension.is_time_dimension?
      return category.to_s.humanize if category.label.kind_of?(Symbol)
      return category.to_s 
    end
  
    def show_active_olap_period(category, options = {})
    
      duration = category.info[:end] - category.info[:begin]
      if duration < 1.hour
        begin_time = category.info[:begin].strftime('%H:%M')
        end_time   = category.info[:end].strftime('%H:%M')    
      elsif duration < 1.day
        begin_time = category.info[:begin].strftime('%H')
        end_time   = category.info[:end].strftime('%H')
      elsif duration < 1.month
        begin_time = category.info[:begin].strftime('%m/%d')
        end_time   = category.info[:end].strftime('%m/%d')      
      else
        begin_time = category.info[:begin].strftime('\'%y/%m/%d')
        end_time   = category.info[:end].strftime('\'%y/%m/%d')
      end
    
      case options[:for]
      when :line_chart; end_time 
      else; "#{begin_time} - #{end_time}"
      end
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
end