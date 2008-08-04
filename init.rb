$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/olap'
ActiveRecord::Base.class_eval { extend ActiveRecord::Olap }
