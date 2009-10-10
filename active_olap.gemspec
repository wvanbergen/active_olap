Gem::Specification.new do |s|
  s.name    = 'active_olap'
  
  # Do not update version and date by hand: this will be done automatically.
  s.version = "0.0.3"
  s.date    = "2009-10-10"
  
  s.summary     = "Extend ActiveRecord with OLAP query functionality."
  s.description = "Extends ActiveRecord with functionality to perform OLAP queries on your data. Includes helper method to ease displaying the results."
  
  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@vanbergen.org']
  s.homepage = 'http://wiki.github.com/wvanbergen/active_olap'
  
  # Do not update files and test_files by hand: this will be done automatically.
  s.files      = %w(test/helper_modules_test.rb spec/spec_helper.rb .gitignore lib/active_olap/helpers/table_helper.rb lib/active_olap/dimension.rb test/active_olap_test.rb lib/active_olap/helpers/display_helper.rb init.rb spec/integration/active_olap_spec.rb lib/active_olap/test/assertions.rb lib/active_olap/category.rb active_olap.gemspec Rakefile MIT-LICENSE tasks/github-gem.rake README.rdoc lib/active_olap.rb test/helper.rb lib/active_olap/helpers/form_helper.rb lib/active_olap/aggregate.rb spec/unit/cube_spec.rb lib/active_olap/helpers/chart_helper.rb lib/active_olap/cube.rb lib/active_olap/configurator.rb)
  s.test_files = %w(test/helper_modules_test.rb test/active_olap_test.rb spec/integration/active_olap_spec.rb spec/unit/cube_spec.rb)
end
