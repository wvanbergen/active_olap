# load RSpec libraries
require 'rubygems'

require 'datamapper'
require 'data_objects'
require 'do_sqlite3'
require 'do_mysql'

require 'spec'

# Require helper files
Dir[File.dirname(__FILE__) + "/spec_helpers/*.rb"].each { |f| require f }

# Load Active OLAP files
$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'active_olap'


Spec::Runner.configure do |configuration|
  configuration.include Debugging
  
  configuration.before(:all) do
    DataMapper.setup(:default, 'sqlite3::memory:')
    DataMapper.auto_migrate!
    
    ActiveOLAP.connection = DataMapper.repository(:default).adapter.send(:open_connection)
  end
  
  configuration.after(:all) do
    DataMapper.repository(:default).adapter.send(:close_connection, ActiveOLAP.connection)
  end
end
