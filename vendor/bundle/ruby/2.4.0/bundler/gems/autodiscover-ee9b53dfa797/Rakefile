require "bundler/gem_tasks"
require "rake/testtask"

task :default => :test

Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
end

desc "Open a Pry console for this library"
task :console do
  require "pry"
  require "autodiscover"
  ARGV.clear
  Pry.start
end
