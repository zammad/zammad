require "bundler/gem_tasks"
require "rake/testtask"
require 'rubocop/rake_task'

RuboCop::RakeTask.new

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.warning = true
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test
