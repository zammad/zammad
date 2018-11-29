#!/usr/bin/env ruby

#
# if run as script, load the file as library while starting irb 
#
if __FILE__ == $0
  irb = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'
  ENV['ADAPTER'] = ARGV[0]
  exec "#{irb} -f -r #{$0} --simple-prompt"
end

#
# check if the given adapter is supported (default: mysql)
#
adapters = %w[mysql sqlite oracle oracle_enhanced postgresql ibm_db]
adapter = ENV['ADAPTER'] || 'mysql'
unless adapters.include? adapter
  puts "Usage: #{__FILE__} <adapter>"
  puts ''
  puts 'Adapters: '
  puts adapters.map{ |adapter| "    #{adapter}" }.join("\n")
  exit 1
end

#
# load all necessary libraries
#
require 'rubygems'
require 'local/database_connections'

$LOAD_PATH.unshift 'lib'

begin
  require 'local/paths'
  $LOAD_PATH.unshift "#{ENV['EDGE_RAILS_DIR']}/active_record/lib"  if ENV['EDGE_RAILS_DIR']
  $LOAD_PATH.unshift "#{ENV['EDGE_RAILS_DIR']}/activesupport/lib" if ENV['EDGE_RAILS_DIR']
rescue
end

require 'active_support'
require 'active_record'

require "test/connections/native_#{adapter}/connection"
require 'composite_primary_keys'

PROJECT_ROOT = File.join(File.dirname(__FILE__), '..')
Dir[File.join(PROJECT_ROOT,'test/fixtures/*.rb')].each { |model| require model }

