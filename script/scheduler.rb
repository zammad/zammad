#!/usr/bin/env ruby
# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/


$LOAD_PATH << './lib'
require 'rubygems'
require 'daemons'
dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

daemon_options = {
  :multiple   => true,
  :dir_mode   => :normal,
  :dir        => File.join(dir, 'tmp', 'pids'),
  :backtrace  => true
}

runner_count = 2

(1..runner_count).each {|count|
  name = 'scheduler_runner' + count.to_s
  Daemons.run_proc(name, daemon_options) do
    if ARGV.include?('--')
      ARGV.slice! 0..ARGV.index('--')
    else
      ARGV.clear
    end

    Dir.chdir dir
    RAILS_ENV = ARGV.first || ENV['RAILS_ENV'] || 'development'

    $stdout.reopen( dir + "/log/" + name + "_out.log", "w")
    $stderr.reopen( dir + "/log/" + name + "_err.log", "w")
    require File.join(dir, "config", "environment")
    require 'scheduler'

    Scheduler.run(count, runner_count)
  end
}

name = 'scheduler_worker'
Daemons.run_proc(name, daemon_options) do
  if ARGV.include?('--')
    ARGV.slice! 0..ARGV.index('--')
  else
    ARGV.clear
  end

  Dir.chdir dir
  RAILS_ENV = ARGV.first || ENV['RAILS_ENV'] || 'development'

  $stdout.reopen( dir + "/log/" + name + "_out.log", "w")
  $stderr.reopen( dir + "/log/" + name + "_err.log", "w")
  require File.join(dir, "config", "environment")
  require 'scheduler'

  Scheduler.worker
end


