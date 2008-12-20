module ActiveOLAP::Helpers
  module FormHelper
  
    def select_olap_dimension_tag(klass, dim_index = 1, options = {}, html_options = {})    
      dimensions = klass.active_olap_dimensions.map { |l, dim| [l, ActiveOLAP::Dimension.create(klass, l)] }
      dimensions.delete_if { |(l, dim)| dim.is_time_dimension? }.map { |(l, dim)| [l, show_active_olap_dimension(dim)] }
      select_tag "dimension[#{dim_index}][name]", options_for_select(dimensions, nil), html_options
    end
  
    def select_olap_time_dimension_tag(klass, dim_index = 1, options = {}, html_options = {})
      dimensions = klass.active_olap_dimensions.map { |l, dim| [l, ActiveOLAP::Dimension.create(klass, l)] }
      dimensions.delete_if { |(l, dim)| !dim.is_time_dimension? }.map { |(l, dim)| [l, show_active_olap_dimension(dim)] }
      select_tag "dimension[#{dim_index}][name]", options_for_select(dimensions, nil), html_options
    end
  end
end