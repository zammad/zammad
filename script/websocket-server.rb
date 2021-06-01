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

require File.join(dir, 'config', 'environment')

require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'optparse'
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

  $stdout.reopen("#{dir}/log/websocket-server_out.log", 'w').sync = true
  $stderr.reopen("#{dir}/log/websocket-server_err.log", 'w').sync = true
end

before_fork

# Look for -o with argument, and -I and -D boolean arguments
@options = {
  p: 6042,
  b: '0.0.0.0',
  s: false,
  v: false,
  d: false,
  k: '/path/to/server.key',
  c: '/path/to/server.crt',
  i: "#{dir}/tmp/pids/websocket.pid"
}

OptionParser.new do |opts|
  opts.banner = 'Usage: websocket-server.rb start|stop [options]'

  opts.on('-d', '--daemon', 'start as daemon') do |d|
    @options[:d] = d
  end
  opts.on('-v', '--verbose', 'enable debug messages') do |d|
    @options[:v] = d
  end
  opts.on('-p', '--port [OPT]', 'port of websocket server') do |p|
    @options[:p] = p
  end
  opts.on('-b', '--bind [OPT]', 'bind address') do |b|
    @options[:b] = IPAddr.new(b).to_s
  end
  opts.on('-s', '--secure', 'enable secure connections') do |s|
    @options[:s] = s
  end
  opts.on('-i', '--pid [OPT]', 'pid, default is tmp/pids/websocket.pid') do |i|
    @options[:i] = i
  end
  opts.on('-k', '--private-key [OPT]', '/path/to/server.key for secure connections') do |k|
    options[:tls_options] ||= {}
    options[:tls_options][:private_key_file] = k
  end
  opts.on('-c', '--certificate [OPT]', '/path/to/server.crt for secure connections') do |c|
    options[:tls_options] ||= {}
    options[:tls_options][:cert_chain_file] = c
  end
end.parse!

if ARGV[0] != 'start' && ARGV[0] != 'stop'
  puts "Usage: #{File.basename(__FILE__)} start|stop [options]"
  exit
end

if ARGV[0] == 'stop'
  pid = File.read(@options[:i]).to_i
  puts "Stopping websocket server (pid: #{pid})"

  # IMPORTANT: Use SIGTERM (15), not SIGKILL (9)
  # Daemons.rb cleans up the PID file automatically on termination;
  # SIGKILL ends the process immediately and bypasses cleanup.
  # See https://major.io/2010/03/18/sigterm-vs-sigkill/ for more.
  Process.kill(:SIGTERM, pid)

  exit
end

if ARGV[0] == 'start' && @options[:d]
  puts "Starting websocket server on #{@options[:b]}:#{@options[:p]} (secure: #{@options[:s]}, pidfile: #{@options[:i]})"

  # Use Daemons.rb's built-in facility for generating PID files
  Daemons.daemonize(
    app_name: File.basename(@options[:i], '.pid'),
    dir_mode: :normal,
    dir:      File.dirname(@options[:i])
  )

  after_fork(dir)
end

WebsocketServer.run(@options)
