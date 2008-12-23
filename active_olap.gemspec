Gem::Specification.new do |s|
  s.name    = 'active_olap'
  s.version = '0.0.2'
  s.date    = '2008-12-23'
  
  s.summary     = "Extend ActiveRecord with OLAP query functionality"
  s.description = "Extends ActiveRecord with functionality to perform OLAP queries on your data. Includes helper method to ease displaying the results."
  
  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@vanbergen.org']
  s.homepage = 'http://github.com/wvanbergen/active_olap/wikis'
  
  s.files = %w(MIT-LICENSE README.textile Rakefile init.rb lib lib/active_olap lib/active_olap.rb lib/active_olap/aggregate.rb lib/active_olap/category.rb lib/active_olap/configurator.rb lib/active_olap/cube.rb lib/active_olap/dimension.rb lib/active_olap/helpers lib/active_olap/helpers/chart_helper.rb lib/active_olap/helpers/display_helper.rb lib/active_olap/helpers/form_helper.rb lib/active_olap/helpers/table_helper.rb lib/active_olap/test lib/active_olap/test/assertions.rb spec spec/integration spec/integration/active_olap_spec.rb spec/spec_helper.rb spec/unit spec/unit/cube_spec.rb tasks tasks/github-gem.rake tasks/spec.rake tasks/test.rake test test/active_olap_test.rb test/helper.rb test/helper_modules_test.rb)
  s.test_files = %w(test/active_olap_test.rb test/helper_modules_test.rb)
end