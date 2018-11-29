require "bundler/gem_tasks"
require 'rubygems'

task :default => :test

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.libs << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end
