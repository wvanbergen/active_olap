module ActiveRecord::Olap::ChartHelper
  
  def included(base)
    require 'gchartrb'
    base.send :include, ActiveRecord::Olap::DisplayHelper
  end
  
  def active_olap_pie_chart(cube, options = {}, html_options = {})
    raise "Pie charts are only suitable charts for 1-dimensional cubes" if cube.depth > 1
    raise "Pie charts are only supported with a single aggregate"       if cube.aggregates.length > 1
    
    active_olap_1d_pie_chart(cube, options, html_options)
  end

  def active_olap_line_chart(cube, options = {}, html_options = {}) 
    raise "Line charts are only supported with a single aggregate" if cube.aggregates.length > 1
    
    case cube.depth
    when 1; active_olap_1d_line_chart(cube, options, html_options)
    when 2; active_olap_2d_line_chart(cube, options, html_options)
    else;   raise "Multidimensional line charts are not yet supported"
    end
  end

  def active_olap_1d_pie_chart(cube, options = {}, html_options = {})
    
    # set some default options
    options[:size]      ||= '550x300'
    options[:legend]      = true unless options.has_key?(:legend)
    html_options[:alt]  ||= show_active_olap_cube(cube, :for => :pie_chart)
    html_options[:size] ||= options[:size]
    
    chart = GoogleChart::PieChart.new(options[:size])
    chart.show_legend = options[:legend]
    cube.each { |category, value| chart.data show_active_olap_category(category, :for => :pie_chart), value }
    image_tag(chart.to_url, html_options)
  end

  def active_olap_1d_line_chart(cube, options = {}, html_options = {})
    
    # set some default options
    options[:size]      ||= '550x300'
    options[:legend]      = false unless options.has_key?(:legend)
    html_options[:alt]  ||= show_active_olap_cube(cube, :for => :line_chart)
    html_options[:size] ||= options[:size]
    
    chart = GoogleChart::LineChart.new(options[:size])
    labels = cube.categories.map { |cat| show_active_olap_period(cat, :for => :line_chart) }
    
    chart.data(show_active_olap_dimension(cube.dimension, :for => :line_chart), cube.to_a)
    chart.show_legend = options[:legend]
    chart.axis :x, :labels => labels    
    chart.axis :y, :range  => [0, cube.raw_results.max]
    image_tag(chart.to_url, html_options)
  end

  def active_olap_2d_line_chart(cube, options = {}, html_options = {})
    
    # set some default options
    options[:size]      ||= '550x300'
    options[:legend]      = true unless options.has_key?(:legend) && options[:legend] == false
    colors = options.has_key?(:colors) ? options[:colors].clone : ['222222', '444444', '666666', '888888', 'aaaaaa']
    html_options[:alt]  ||= show_active_olap_cube(cube, :for => :line_chart)
    html_options[:size] ||= options[:size]
    
    chart = GoogleChart::LineChart.new(options[:size])
    
    cube.transpose.each do |cat, sub_cube| 
      chart.data show_active_olap_category(cat, :for => :line_chart), sub_cube.raw_results, colors.shift || '000000'
    end
    
    chart.show_legend = options[:legend]
    labels = cube.categories.map { |cat| show_active_olap_period(cat, :for => :line_chart) }    
    chart.axis :x, :labels => labels        
    chart.axis :y, :range  => [0, cube.raw_results.flatten.max]
    image_tag(chart.to_url, html_options)
  end  
  
end