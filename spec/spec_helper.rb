# load RSpec libraries
require 'rubygems'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')

# Load Active OLAP files
require 'active_olap'

module Debugging
  def pre(string)
    puts "<pre>"
    puts string
    puts "</pre>"
  end
end

Spec::Runner.configure do |configuration|
  configuration.include Debugging
end