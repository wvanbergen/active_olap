module ActiveRecord::Olap::TableHelper
  
  
  def self.included(base)
    base.send :include, ActiveRecord::Olap::DisplayHelper
  end
  
  def active_olap_1d_table(cube, html_options = {})    
    
    raise "Only suitable for 1D cubes" unless cube.depth == 1
    
    content_tag(:table, html_options.merge(:class => "active-olap table 1d")) do
      cube.map do |category, value|
        content_tag(:tr, :id => "category-#{category.label}", :class => 'category') do
          # TODO: multiple aggregates
          content_tag(:th, show_active_olap_category(cube.dimension, category), :class => 'label') <<
          if cube.aggregates.length > 1
            cube.aggregates.map do |agg|
              content_tag(:td, show_active_olap_value(category, agg, value[agg.label]), :class => "value #{agg.label}") + "\n"
            end.join
          else
            content_tag(:td, show_active_olap_value(category, cube.aggregates.first, value), :class => 'value') + "\n"
          end
        end
      end.join
    end
  end


  def active_olap_2d_table(cube, html_options = {})
    
    raise "Only suitable for 2D cubes" unless cube.depth == 2
    raise "Only 1 aggregate supported" if cube.aggregates.length > 1
    
    content_tag(:table, html_options.merge(:class => "active-olap table 2d")) do    
      content_tag(:thead) do
        content_tag(:tr) do
          content_tag(:th, '&nbsp;') + "\n\t" +
          cube.dimensions[1].categories.map do |category|
            content_tag(:th, show_active_olap_category(cube.dimensions[1], category), :class => 'category', :id => "category-#{category.label}")
          end.join
        end
      end << "\n" <<
      content_tag(:tbody) do
        cube.map do |category, sub_cube|
          content_tag(:tr, :class => 'category', :id => "category-#{category.label}") do
            "\t\n" + content_tag(:th, show_active_olap_category(cube.dimension, category)) + 
            sub_cube.map do |category, value|
              content_tag(:td, show_active_olap_value(category, cube.aggregates.first, value), :class => 'value')
            end.join
          end
        end
      end
    end
  end

  def active_olap_table(cube, html_options = {})
    
  end
  
end