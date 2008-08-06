module ActiveRecord::Olap::ChartHelper
  
  def included(base)
    require 'gchartrb'
    base.send :include, ActiveRecord::Olap::DisplayHelper
  end
  
  def active_olap_1d_pie(cube, options = {})
    chart = GoogleChart::PieChart.new('550x300')
    cube.each do |category, value|
      chart.data sho_category(cube.dimension, category), value
    end
    image_tag(chart.to_url, :size => '550x300', :alt => 'Active OLAP pie chart')
  end

  def active_olap_1d_trend(cube, options = {})
    chart = GoogleChart::LineChart.new('550x300')
    labels = cube.categories.map { |cat| show_period(cube.dimension, cat, :chart => true) }
    
    chart.data('trend', cube.to_a)
    chart.show_legend = false
    chart.axis :x, :labels => labels    
    chart.axis :y, :range  => [0, cube.raw_results.max]
    image_tag(chart.to_url, :size => '550x300', :alt => 'Active OLAP trend chart')
  end

  
  
end