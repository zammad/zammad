require 'rspec/core/rake_task'

task :default => :spec

desc "Run all specs in spec directory"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
  t.ruby_opts = "-w"
end
