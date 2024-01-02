#!/usr/bin/env ruby
# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'daemons'

#
# Generic daemonization script for legacy CI tests.
#

def exit_with_usage
  puts 'Usage: daemonize.rb start|stop -- $name_of_pidfile $commandline'
  exit false
end

dir = File.expand_path(File.join(__dir__, '../..'))

daemon_options = {
  multiple:  false,
  dir_mode:  :normal,
  dir:       File.join(dir, 'tmp', 'pids'),
  backtrace: true
}

separator_index = ARGV.index('--')
exit_with_usage if separator_index.nil?
args = ARGV[(separator_index + 1)..]
exit_with_usage if args.count < 2

Daemons.run_proc(args[0], daemon_options) do
  Dir.chdir dir
  exec(args[1])
end
