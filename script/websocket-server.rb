#!/usr/bin/env ruby
# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

$LOAD_PATH << './lib'
require 'rubygems'

# load rails env
dir = File.expand_path('..', __dir__)
Dir.chdir dir
RAILS_ENV = ENV['RAILS_ENV'] || 'development'

require 'rails/all'
require 'bundler'
require File.join(dir, 'config', 'environment')
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'optparse'
require 'daemons'
require 'sessions'

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

  $stdout.reopen( "#{dir}/log/websocket-server_out.log", 'w').sync = true
  $stderr.reopen( "#{dir}/log/websocket-server_err.log", 'w').sync = true
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
  i: Dir.pwd.to_s + '/tmp/pids/websocket.pid'
}

tls_options = {}
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
    tls_options[:private_key_file] = k
  end
  opts.on('-c', '--certificate [OPT]', '/path/to/server.crt for secure connections') do |c|
    tls_options[:cert_chain_file] = c
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
    dir: File.dirname(@options[:i])
  )

  after_fork(dir)
end

@clients = {}
Rails.configuration.interface = 'websocket'
EventMachine.run do
  EventMachine::WebSocket.start( host: @options[:b], port: @options[:p], secure: @options[:s], tls_options: tls_options ) do |ws|

    # register client connection
    ws.onopen do |handshake|
      headers = handshake.headers
      remote_ip = get_remote_ip(headers)
      client_id = ws.object_id.to_s
      log 'notice', 'Client connected.', client_id
      Sessions.create( client_id, {}, { type: 'websocket' } )

      if !@clients.include? client_id
        @clients[client_id] = {
          websocket:   ws,
          last_ping:   Time.now.utc.to_i,
          error_count: 0,
          headers:     headers,
          remote_ip:   remote_ip,
        }
      end
    end

    # unregister client connection
    ws.onclose do
      client_id = ws.object_id.to_s
      log 'notice', 'Client disconnected.', client_id

      # removed from current client list
      if @clients.include? client_id
        @clients.delete client_id
      end

      Sessions.destroy(client_id)
    end

    # manage messages
    ws.onmessage do |msg|

      client_id = ws.object_id.to_s
      log 'debug', "received: #{msg} ", client_id
      begin
        data = JSON.parse(msg)
      rescue => e
        log 'error', "can't parse message: #{msg}, #{e.inspect}", client_id
        next
      end

      # check if connection not already exists
      next if !@clients[client_id]

      Sessions.touch(client_id) # rubocop:disable Rails/SkipsModelValidations
      @clients[client_id][:last_ping] = Time.now.utc.to_i

      # spool messages for new connects
      if data['spool']
        Sessions.spool_create(data)
      end

      if data['event']
        log 'debug', "execute event '#{data['event']}'", client_id
        message = Sessions::Event.run(
          event: data['event'],
          payload: data,
          session: @clients[client_id][:session],
          remote_ip: @clients[client_id][:remote_ip],
          client_id: client_id,
          clients: @clients,
          options: @options,
        )
        if message
          websocket_send(client_id, message)
        end
      else
        log 'error', "unknown message '#{data.inspect}'", client_id
      end
    end
  end

  # check unused connections
  EventMachine.add_timer(0.5) do
    check_unused_connections
  end

  # check open unused connections, kick all connection without activitie in the last 2 minutes
  EventMachine.add_periodic_timer(120) do
    check_unused_connections
  end

  EventMachine.add_periodic_timer(20) do

    # websocket
    log 'notice', "Status: websocket clients: #{@clients.size}"
    @clients.each_key do |client_id|
      log 'notice', 'working...', client_id
    end

    # ajax
    client_list = Sessions.list
    clients = 0
    client_list.each_value do |client|
      next if client[:meta][:type] == 'websocket'
      clients = clients + 1
    end
    log 'notice', "Status: ajax clients: #{clients}"
    client_list.each do |client_id, client|
      next if client[:meta][:type] == 'websocket'
      log 'notice', 'working...', client_id
    end

  end

  EventMachine.add_periodic_timer(0.4) do
    next if @clients.size.zero?
    #log 'debug', 'checking for data to send...'
    @clients.each do |client_id, client|
      next if client[:disconnect]
      log 'debug', 'checking for data...', client_id
      begin
        queue = Sessions.queue(client_id)
        next if queue.blank?
        log 'notice', 'send data to client', client_id
        websocket_send(client_id, queue)
      rescue => e
        log 'error', 'problem:' + e.inspect, client_id

        # disconnect client
        client[:error_count] += 1
        if client[:error_count] > 20
          if @clients.include? client_id
            @clients.delete client_id
          end
        end
      end
    end
  end

  def get_remote_ip(headers)
    return headers['X-Forwarded-For'] if headers && headers['X-Forwarded-For']
    nil
  end

  def websocket_send(client_id, data)
    msg = if data.class != Array
            "[#{data.to_json}]"
          else
            data.to_json
          end
    log 'debug', "send #{msg}", client_id
    if !@clients[client_id]
      log 'error', "no such @clients for #{client_id}", client_id
      return
    end
    @clients[client_id][:websocket].send(msg)
  end

  def check_unused_connections
    log 'notice', 'check unused idle connections...'

    idle_time_in_sec = 4 * 60

    # close unused web socket sessions
    @clients.each do |client_id, client|

      next if ( client[:last_ping].to_i + idle_time_in_sec ) >= Time.now.utc.to_i

      log 'notice', 'closing idle websocket connection', client_id

      # remember to not use this connection anymore
      client[:disconnect] = true

      # try to close regular
      client[:websocket].close_websocket

      # delete session from client list
      sleep 0.3
      @clients.delete(client_id)
    end

    # close unused ajax long polling sessions
    clients = Sessions.destroy_idle_sessions(idle_time_in_sec)
    clients.each do |client_id|
      log 'notice', 'closing idle long polling connection', client_id
    end
  end

  def log(level, data, client_id = '-')
    if !@options[:v]
      return if level == 'debug'
    end
    puts "#{Time.now.utc.iso8601}:client(#{client_id}) #{data}"
    #puts "#{Time.now.utc.iso8601}:#{ level }:client(#{ client_id }) #{ data }"
  end

end
