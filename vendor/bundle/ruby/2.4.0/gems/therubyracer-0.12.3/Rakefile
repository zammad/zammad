#!/usr/bin/env rake
require 'bundler/setup'
require "bundler/gem_tasks"

task :clean do
  sh "rm -rf lib/v8/init.bundle lib/v8/init.so"
  sh "rm -rf pkg"
end

require "rake/extensiontask"
Rake::ExtensionTask.new("init", eval(File.read("therubyracer.gemspec"))) do |ext|
  ext.ext_dir = "ext/v8"
  ext.lib_dir = "lib/v8"
  ext.source_pattern = "*.{cc,h}"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |task|
  task.rspec_opts = '--tag ~memory --tag ~threads'
end

task :sanity => [:clean, :compile] do
  sh %q{ruby -Ilib -e "require 'v8'"}
end

NativeGem = "pkg/therubyracer-#{V8::VERSION}-#{Gem::Platform.new(RUBY_PLATFORM)}.gem"
file NativeGem => :build do
  require "rubygems/compiler"
  compiler = Gem::Compiler.new("pkg/therubyracer-#{V8::VERSION}.gem", 'pkg')
  compiler.compile
end

desc "Build #{NativeGem} into the pkg directory"
task "build:native" => NativeGem

desc "Build and install #{File.basename NativeGem} into system gems"
task "install:native" => "build:native" do
  sh "gem install #{NativeGem}"
end

task :default => :spec

