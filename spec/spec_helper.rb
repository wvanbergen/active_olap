$:.reject! { |e| e.include? 'TextMate' }
$:.unshift(File.dirname(__FILE__) + '/../lib')

# load RSpec libraries
require 'rubygems'
gem 'rspec', '>=1.1.11'
require 'test/unit'
require 'spec'


# Load Active OLAP files
require 'active_record'
require 'active_olap'
