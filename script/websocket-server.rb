#!/usr/bin/env ruby
# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/
# rubocop:disable Rails/TimeZone

$LOAD_PATH << './lib'
require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'sessions'
require 'optparse'
require 'daemons'

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
    @options[:b] = b
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

puts "Starting websocket server on #{ @options[:b] }:#{ @options[:p] } (secure:#{ @options[:s] },pid:#{@options[:i]})"
#puts options.inspect

if ARGV[0] == 'stop'

  # read pid
  pid = File.open( @options[:i].to_s  ).read
  pid.gsub!(/\r|\n/, '')

  # kill
  Process.kill( 9, pid.to_i )
  exit
end
if ARGV[0] == 'start' && @options[:d]

  Daemons.daemonize

  # create pid file
  daemon_pid = File.new( @options[:i].to_s, 'w' )
  daemon_pid.sync = true
  daemon_pid.puts(Process.pid.to_s)
  daemon_pid.close
end

@clients = {}
EventMachine.run {
  EventMachine::WebSocket.start( host: @options[:b], port: @options[:p], secure: @options[:s], tls_options: tls_options ) do |ws|

    # register client connection
    ws.onopen {
      client_id = ws.object_id.to_s
      log 'notice', 'Client connected.', client_id
      Sessions.create( client_id, {}, { type: 'websocket' } )

      if !@clients.include? client_id
        @clients[client_id] = {
          websocket:   ws,
          last_ping:   Time.now.utc.to_i,
          error_count: 0,
        }
      end
    }

    # unregister client connection
    ws.onclose {
      client_id = ws.object_id.to_s
      log 'notice', 'Client disconnected.', client_id

      # removed from current client list
      if @clients.include? client_id
        @clients.delete client_id
      end

      Sessions.destory( client_id )
    }

    # manage messages
    ws.onmessage { |msg|

      client_id = ws.object_id.to_s
      log 'debug', "received: #{ msg } ", client_id
      begin
        data = JSON.parse(msg)
      rescue => e
        log 'error', "can't parse message: #{ msg }, #{ e.inspect }", client_id
        next
      end

      # check if connection already exists
      next if !@clients[client_id]

      # spool messages for new connects
      if data['spool']
        Sessions.spool_create(msg)
      end

      # get spool messages and send them to new client connection
      if data['action'] == 'spool'

        # error handling
        if data['timestamp']
          log 'notice', "request spool data > '#{Time.at(data['timestamp']).utc.iso8601}'", client_id
        else
          log 'notice', 'request spool with init data', client_id
        end

        if @clients[client_id] && @clients[client_id][:session] && @clients[client_id][:session]['id']
          spool = Sessions.spool_list( data['timestamp'], @clients[client_id][:session]['id'] )
          spool.each { |item|

            # create new msg to push to client
            msg = JSON.generate( item[:message] )
            if item[:type] == 'direct'
              log 'notice', "send spool to (user_id=#{ @clients[client_id][:session]['id'] })", client_id
              websocket_send(msg, client_id)
            else
              log 'notice', 'send spool', client_id
              websocket_send(msg, client_id)
            end
          }
        else
          log 'error', "can't send spool, session not authenticated", client_id
        end

        # send spool:sent event to client
        log 'notice', 'send spool:sent event', client_id
        message = {
          event: 'spool:sent',
          data: {
            timestamp: Time.now.utc.iso8601.to_i.to_s,
          },
        }
        websocket_send(message.to_json, client_id)
      end

      # get session
      if data['action'] == 'login'
        @clients[client_id][:session] = data['session']
        Sessions.create( client_id, data['session'], { type: 'websocket' } )

        # remember ping, send pong back
      elsif data['action'] == 'ping'
        Sessions.touch(client_id)
        @clients[client_id][:last_ping] = Time.now.utc.to_i
        message = {
          action: 'pong',
        }
        websocket_send(message.to_json, client_id)

        # broadcast
      elsif data['action'] == 'broadcast'

        # list all current clients
        client_list = Sessions.list
        client_list.each {|local_client_id, local_client|
          if local_client_id != client_id

            # broadcast to recipient list
            if data['recipient']
              if data['recipient'].class != Hash
                log 'error', "recipient attribute isn't a hash '#{ data['recipient'].inspect }'"
              else
                if !data['recipient'].key?('user_id')
                  log 'error', "need recipient.user_id attribute '#{ data['recipient'].inspect }'"
                else
                  if data['recipient']['user_id'].class != Array
                    log 'error', "recipient.user_id attribute isn't an array '#{ data['recipient']['user_id'].inspect }'"
                  else
                    data['recipient']['user_id'].each { |user_id|

                      next if local_client[:user]['id'].to_i != user_id.to_i

                      log 'notice', "send broadcast from (#{client_id}) to (user_id=#{user_id})", local_client_id
                      if local_client[:meta][:type] == 'websocket' && @clients[ local_client_id ]
                        websocket_send(msg, local_client_id)
                      else
                        Sessions.send(local_client_id, data)
                      end
                    }
                  end
                end
              end

              # broadcast every client
            else
              log 'notice', "send broadcast from (#{client_id})", local_client_id
              if local_client[:meta][:type] == 'websocket' && @clients[ local_client_id ]
                websocket_send(msg, local_client_id)
              else
                Sessions.send(local_client_id, data)
              end
            end
          else
            log 'notice', 'do not send broadcast to it self', client_id
          end
        }
      end
    }
  end

  # check unused connections
  EventMachine.add_timer(0.5) {
    check_unused_connections
  }

  # check open unused connections, kick all connection without activitie in the last 2 minutes
  EventMachine.add_periodic_timer(120) {
    check_unused_connections
  }

  EventMachine.add_periodic_timer(20) {

    # websocket
    log 'notice', "Status: websocket clients: #{ @clients.size }"
    @clients.each { |client_id, _client|
      log 'notice', 'working...', client_id
    }

    # ajax
    client_list = Sessions.list
    clients = 0
    client_list.each {|_client_id, client|
      next if client[:meta][:type] == 'websocket'
      clients = clients + 1
    }
    log 'notice', "Status: ajax clients: #{ clients }"
    client_list.each {|client_id, client|
      next if client[:meta][:type] == 'websocket'
      log 'notice', 'working...', client_id
    }

  }

  EventMachine.add_periodic_timer(0.4) {
    next if @clients.size == 0
    #log 'debug', 'checking for data to send...'
    @clients.each { |client_id, client|
      next if client[:disconnect]
      log 'debug', 'checking for data...', client_id
      begin
        queue = Sessions.queue( client_id )
        if queue && queue[0]
          log 'notice', 'send data to client', client_id
          websocket_send(queue.to_json, client_id)
        end
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
    }
  }

  def websocket_send(msg, client_id)
    log 'debug', "send #{msg}", client_id
    if !@clients[client_id]
      log 'error', "no such @clients for #{client_id}", client_id
      return
    end
    @clients[client_id][:websocket].send( "[#{ msg }]" )
  end

  def check_unused_connections
    log 'notice', 'check unused idle connections...'

    idle_time_in_sec = 4 * 60

    # close unused web socket sessions
    @clients.each { |client_id, client|

      next if ( client[:last_ping].to_i + idle_time_in_sec ) >= Time.now.utc.to_i

      log 'notice', 'closing idle websocket connection', client_id

      # remember to not use this connection anymore
      client[:disconnect] = true

      # try to close regular
      client[:websocket].close_websocket

      # delete session from client list
      sleep 0.3
      @clients.delete(client_id)
    }

    # close unused ajax long polling sessions
    clients = Sessions.destory_idle_sessions(idle_time_in_sec)
    clients.each { |client_id|
      log 'notice', 'closing idle long polling connection', client_id
    }
  end

  def log( level, data, client_id = '-' )
    if !@options[:v]
      return if level == 'debug'
    end
    puts "#{Time.now.utc.iso8601}:client(#{ client_id }) #{ data }"
    #puts "#{Time.now.utc.iso8601}:#{ level }:client(#{ client_id }) #{ data }"
  end

}
