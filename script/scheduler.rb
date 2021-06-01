#!/usr/bin/env ruby
# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

begin
  load File.expand_path('../bin/spring', __dir__)
rescue LoadError => e
  raise if e.message.exclude?('spring')
end

dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Dir.chdir dir

require 'bundler'
require 'daemons'

def before_fork
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

  # Spring redirects STDOUT and STDERR to /dev/null
  # before we get here. This causes the `reopen` lines
  # below to fail because the handles are already
  # opened for write
  if defined?(Spring)
    $stdout.close
    $stderr.close
  end

  $stdout.reopen("#{dir}/log/scheduler_out.log", 'w')
  $stderr.reopen("#{dir}/log/scheduler_err.log", 'w')
end

before_fork

daemon_options = {
  multiple:  false,
  dir_mode:  :normal,
  dir:       File.join(dir, 'tmp', 'pids'),
  backtrace: true
}

Daemons.run_proc('scheduler', daemon_options) do

  after_fork(dir)

  require File.join(dir, 'config', 'environment')

  Rails.logger.info 'Scheduler started.'
  at_exit do

    # use process title for stop log entry
    # if differs from default process title
    title = 'Scheduler'
    if $PROGRAM_NAME != 'scheduler.rb'
      title = $PROGRAM_NAME
    end

    Rails.logger.info "#{title} stopped."
  end

  begin
    Scheduler.threads
  rescue Interrupt
    nil
  end
end
