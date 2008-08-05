module ActiveRecord::Olap::TableHelper
  
  
  def self.included(base)
    base.send :include, ActiveRecord::Olap::DisplayHelper
  end
  
  def active_olap_1d_table(cube, options = {}, html_options = {})    
    
    raise "Only suitable for 1D cubes" unless cube.depth == 1
    
    content_tag(:table, html_options.merge(:class => "active-olap table 1d")) do
      cube.map do |category, value|
        content_tag(:tr, :id => "category-#{category.label}", :class => 'category') do
          # TODO: multiple aggregates
          content_tag(:th, show_active_olap_category(category), :class => 'label') <<
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


  def active_olap_2d_table(cube, options = {}, html_options = {})
    
    raise "Only suitable for 2D cubes" unless cube.depth == 2
    raise "Only 1 aggregate supported" if cube.aggregates.length > 1
    
    content_tag(:table, html_options.merge(:class => "active-olap table 2d")) do    
      content_tag(:thead) do
        content_tag(:tr) do
          content_tag(:th, '&nbsp;') + "\n\t" +
          cube.dimensions[1].categories.map do |category|
            content_tag(:th, show_active_olap_category(category), :class => 'category', :id => "category-#{category.label}")
          end.join
        end
      end << "\n" <<
      content_tag(:tbody) do
        cube.map do |category, sub_cube|
          content_tag(:tr, :class => 'category', :id => "category-#{category.label}") do
            "\t\n" + content_tag(:th, show_active_olap_category(category)) + 
            sub_cube.map do |category, value|
              content_tag(:td, show_active_olap_value(category, cube.aggregates.first, value), :class => 'value')
            end.join
          end
        end
      end
    end
  end

  def active_olap_table(cube, options = {}, html_options = {})
    content_tag(:table, :class => "active-olap table #{cube.depth}d" ) do
      content_tag(:thead) do
        
      end << "\n" <<
      content_tag(:tbody) { active_olap_table_bodypart(cube, options) }
    end
  end
  
  def active_olap_table_bodypart(cube, options = {}, intermediate = [], counts = [])
    cube.map do |category, result|
      if result.kind_of?(ActiveRecord::Olap::Cube)
        active_olap_table_bodypart(result, options, intermediate.push(category), counts.push(result.categories.length))
      else
        content_tag(:tr) do
          cells = intermediate.map do |c| 
            cat_count = counts.shift
            content_tag(:th, c.label.to_s, { :rowspan => cat_count * counts.inject(1) { |i, count| i * count } } ) 
          end.join
          intermediate.clear
          
          cells += content_tag(:th, show_active_olap_category(category)) # TODO values
          cells += if cube.aggregates.length == 1
              content_tag(:td, show_active_olap_value(category, cube.aggregates.first, result))
            else
              cube.aggregates.map { |agg| content_tag(:td, show_active_olap_value(category, agg, result[agg.label])) }.join
            end
        end
      end
    end.join
  end
end