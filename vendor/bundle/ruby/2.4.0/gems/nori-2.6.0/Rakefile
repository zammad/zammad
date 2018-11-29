require "bundler/gem_tasks"

desc "Benchmark Nori parsers"
task :benchmark do
  require "benchmark/benchmark"
end

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new

task :default => :spec
task :test => :spec
