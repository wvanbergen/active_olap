require 'rake/testtask'
 
desc 'Test the scoped_search plugin.'
Rake::TestTask.new(:test) do |t|
  t.pattern = 'test/**/test_*.rb'
  t.verbose = true
  t.libs << 'test'
end