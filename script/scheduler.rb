#!/usr/bin/env ruby
# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

$LOAD_PATH << './lib'
require 'rubygems'
require 'daemons'
dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))

daemon_options = {
  multiple: false,
  dir_mode: :normal,
  dir: File.join(dir, 'tmp', 'pids'),
  backtrace: true
}

name = 'scheduler'
Daemons.run_proc(name, daemon_options) do
  if ARGV.include?('--')
    ARGV.slice! 0..ARGV.index('--')
  else
    ARGV.clear
  end

  Dir.chdir dir
  RAILS_ENV = ARGV.first || ENV['RAILS_ENV'] || 'development'

  $stdout.reopen( dir + '/log/' + name + '_out.log', 'w')
  $stderr.reopen( dir + '/log/' + name + '_err.log', 'w')
  require File.join(dir, 'config', 'environment')
  require 'scheduler'

  Scheduler.threads
end
