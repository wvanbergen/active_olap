Gem::Specification.new do |s|
  s.name    = 'active_olap'
  s.version = '0.0.1'
  s.date    = '2008-12-19'
  
  s.summary     = "Extend ActiveRecord with OLAP query functionality"
  s.description = "Extends ActiveRecord with functionality to perform OLAP queries on your data. Includes helper method to ease displaying the results."
  
  s.authors  = ['Willem van Bergen']
  s.email    = ['willem@vanbergen.org']
  s.homepage = 'http://github.com/wvanbergen/active_olap/wikis'
  
  s.files = %w(CHANGELOG LICENSE README.textile Rakefile TODO init.rb lib lib/scoped_search lib/scoped_search.rb lib/scoped_search/query_conditions_builder.rb lib/scoped_search/query_language_parser.rb lib/scoped_search/reg_tokens.rb test test/query_conditions_builder_test.rb test/query_language_test.rb test/search_for_test.rb test/tasks.rake test/test_helper.rb)
  s.test_files = %w(test/query_conditions_builder_test.rb test/query_language_test.rb test/search_for_test.rb)
end