#!/usr/bin/env ruby
# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

dir = File.expand_path(File.join(File.dirname(__FILE__), '..'))
Dir.chdir dir

require 'bundler'
require 'daemons'

DEPRECATION_WARNING = "'script/scheduler.rb' is deprecated and will be removed with Zammad 6. Please use 'script/background-worker.rb' instead - note that this will not daemonize but always stay in the foreground.".freeze
warn "DEPRECATION WARNING: #{DEPRECATION_WARNING}"

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
  ActiveSupport::Deprecation.warn DEPRECATION_WARNING
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
    config = BackgroundServices::ServiceConfig.configuration_from_env(ENV)
    BackgroundServices.new(config).run
  rescue Interrupt
    nil
  end
end
