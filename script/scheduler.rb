#!/usr/bin/env ruby
# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

$LOAD_PATH << './lib'
require 'rubygems'

# load rails env
dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Dir.chdir dir
RAILS_ENV = ENV['RAILS_ENV'] || 'development'

require 'rails/all'
require 'bundler'
require File.join(dir, 'config', 'environment')
require 'daemons'

def before_fork

  # clear all connections before for, reconnect later ActiveRecord::Base.connection.reconnect!
  # issue #1405 - Scheduler not running because of Bad file descriptor in PGConsumeInput()
  # https://github.com/zammad/zammad/issues/1405
  # see also https://bitbucket.org/ged/ruby-pg/issues/260/frequent-crashes-with-multithreading
  ActiveRecord::Base.clear_all_connections!

  # remember open file handles
  @files_to_reopen = []
  ObjectSpace.each_object(File) do |file|
    @files_to_reopen << file if !file.closed?
  end
end

def after_fork(dir)
  Dir.chdir dir

  # Re-open file handles
  @files_to_reopen.each do |file|
    file.reopen file.path, 'a+'
    file.sync = true
  end

  $stdout.reopen("#{dir}/log/scheduler_out.log", 'w')
  $stderr.reopen("#{dir}/log/scheduler_err.log", 'w')
end

before_fork

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

  after_fork(dir)

  Rails.logger.info 'Scheduler started.'

  at_exit do
    Rails.logger.info 'Scheduler stopped.'
  end

  require 'scheduler'
  Scheduler.threads
end
