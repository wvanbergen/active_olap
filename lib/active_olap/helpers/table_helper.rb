module ActiveOLAP::Helpers
  module TableHelper
  
  
    def self.included(base)
      base.send :include, ActiveOLAP::Helpers::DisplayHelper
    end
  
    def active_olap_matrix(cube, options = {}, html_options = {})
    
      raise "Only suitable for 2D cubes" unless cube.depth == 2
      raise "Only 1 aggregate supported" if cube.aggregates.length > 1
    
      content_tag(:table, html_options.merge(:class => "active-olap table 2d")) do    
        content_tag(:thead) do
          content_tag(:tr) do
            content_tag(:th, '&nbsp;') + "\n\t" +
            cube.dimensions[1].categories.map do |category|
              content_tag(:th, show_active_olap_category(category, :for => :matrix), :class => 'category', :id => "category-#{category.label}")
            end.join
          end
        end << "\n" <<
        content_tag(:tbody) do
          cube.map do |category, sub_cube|
            content_tag(:tr, :class => 'category', :id => "category-#{category.label}") do
              "\t\n" + content_tag(:th, show_active_olap_category(category, :for => :matrix)) + 
              sub_cube.map do |category, value|
                content_tag(:td, show_active_olap_value(category, cube.aggregates.first, value, :for => :matrix), :class => 'value')
              end.join
            end
          end
        end
      end
    end

    def active_olap_table(cube, options = {}, html_options = {})
      content_tag(:table, :class => "active-olap table #{cube.depth}d" ) do
        content_tag(:thead) do
          content_tag(:tr) do
            content_tag(:th, '&nbsp;', :class => 'categories', :colspan => cube.depth) <<
            cube.aggregates.map { |agg| content_tag(:th, show_active_olap_aggregate(agg, :for => :table), :class => "aggregate #{agg.label}") }.join
          end
        end << "\n" <<
        content_tag(:tbody) { active_olap_table_bodypart(cube, options) }
      end
    end
  
    def active_olap_table_bodypart(cube, options = {}, intermediate = [], counts = [])
      cube.map do |category, result|
        if result.kind_of?(ActiveOLAP::Cube)
          active_olap_table_bodypart(result, options, intermediate.push(category), counts.push(result.categories.length))
        else
          content_tag(:tr) do
            cells = intermediate.map do |c| 
              cat_count = counts.shift
              content_tag(:th, c.label.to_s, { :class => 'category', :rowspan => cat_count * counts.inject(1) { |i, count| i * count } } ) 
            end.join
            intermediate.clear
          
            cells << content_tag(:th, show_active_olap_category(category, :for => :table), :class => "category") # TODO values
            cells << if result.kind_of?(Hash)
                cube.aggregates.map { |agg| content_tag(:td, show_active_olap_value(category, agg, result[agg.label], :for => :table), :class => "value #{agg.label}") }.join
              else
                content_tag(:td, show_active_olap_value(category, cube.aggregates[0], result, :for => :table), :class => 'value')
              end
          end
        end
      end.join
    end
  end
end