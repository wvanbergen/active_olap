Gem::Specification.new do |s|
  s.name    = 'active_olap'
  
  # Do not update version and date by hand: this will be done automatically.
  s.version = "0.0.4"
  s.date    = "2009-11-20"
  
  s.summary     = "Extend ActiveRecord with OLAP query functionality."
  s.description = "Extends ActiveRecord with functionality to perform OLAP queries on your data. Includes helper method to ease displaying the results."
  
  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@vanbergen.org']
  s.homepage = 'http://wiki.github.com/wvanbergen/active_olap'
  
  # Do not update files and test_files by hand: this will be done automatically.
  s.files      = %w(spec/unit/cube_spec.rb spec/spec_helper.rb lib/active_olap/configurator.rb test/helper_modules_test.rb .gitignore test/active_olap_test.rb lib/active_olap/helpers/table_helper.rb lib/active_olap/helpers/display_helper.rb lib/active_olap/dimension.rb active_olap.gemspec MIT-LICENSE lib/active_olap/category.rb lib/active_olap.rb init.rb Rakefile spec/integration/active_olap_spec.rb lib/active_olap/test/assertions.rb README.rdoc tasks/github-gem.rake lib/active_olap/helpers/form_helper.rb lib/active_olap/helpers/chart_helper.rb test/helper.rb lib/active_olap/cube.rb lib/active_olap/aggregate.rb)
  s.test_files = %w(spec/unit/cube_spec.rb test/helper_modules_test.rb test/active_olap_test.rb spec/integration/active_olap_spec.rb)
end
