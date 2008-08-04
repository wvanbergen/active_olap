module ActiveRecord::Olap::TableHelper
  
  
  def self.included(base)
    base.send :include, ActiveRecord::Olap::DisplayHelper
  end
  
  def active_olap_1d_table(cube, options = {})    
    content_tag(:table, :class => "active-olap table 1d") do
      cube.map do |category, value|
        content_tag(:tr, :id => category.label.to_s) do
          content_tag(:th, show_category(cube.dimension, category)) + content_tag(:td, value)
        end
      end.join("\n")
    end
  end


  def active_olap_2d_table(cube, options = {})
    
    
  end

  def active_olap_table(cube, options = {})
    
  end
  
end