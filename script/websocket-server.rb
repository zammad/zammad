#!/usr/bin/env ruby

$LOAD_PATH << './lib'
require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'session'
require 'optparse'
require 'daemons'

# Look for -o with argument, and -I and -D boolean arguments
@options = {
  :p => 6042,
  :b => '0.0.0.0',
  :s => false,
  :v => false,
  :d => false,
  :k => '/path/to/server.key',
  :c => '/path/to/server.crt',
  :i => Dir.pwd.to_s + '/tmp/pids/websocket.pid'
}

if ARGV[0] != 'start' && ARGV[0] != 'stop'
  puts "Usage: websocket-server.rb start|stop [options]"
  exit;
end
tls_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: websocket-server.rb start|stop [options]"

  opts.on("-d", "--daemon", "start as daemon") do |d|
    @options[:d] = d
  end
  opts.on("-v", "--verbose", "enable debug messages") do |d|
    @options[:v] = d
  end
  opts.on("-p", "--port [OPT]", "port of websocket server") do |p|
    @options[:p] = p
  end
  opts.on("-b", "--bind [OPT]", "bind address") do |b|
    @options[:b] = b
  end
  opts.on("-s", "--secure", "enable secure connections") do |s|
    @options[:s] = s
  end
  opts.on("-i", "--pid [OPT]", "pid, default is tmp/pids/websocket.pid") do |i|
    @options[:i] = i
  end
  opts.on("-k", "--private-key [OPT]", "/path/to/server.key for secure connections") do |k|
    tls_options[:private_key_file] = k
  end
  opts.on("-c", "--certificate [OPT]", "/path/to/server.crt for secure connections") do |c|
    tls_options[:cert_chain_file] = c
  end
end.parse!

puts "Starting websocket server on #{ @options[:b] }:#{ @options[:p] } (secure:#{ @options[:s].to_s },pid:#{@options[:i].to_s})"
#puts options.inspect

if ARGV[0] == 'stop'

  # read pid
  pid =File.open( @options[:i].to_s  ).read
  pid.gsub!(/\r|\n/, "")

  # kill
  Process.kill( 9, pid.to_i )
  exit
end
if ARGV[0] == 'start'  && @options[:d]

  Daemons.daemonize

  # create pid file
  $daemon_pid = File.new( @options[:i].to_s,"w" )
  $daemon_pid.sync = true
  $daemon_pid.puts(Process.pid.to_s)
  $daemon_pid.close
end

@clients = {}
@spool   = []
EventMachine.run {
  EventMachine::WebSocket.start( :host => @options[:b], :port => @options[:p], :secure => @options[:s], :tls_options => tls_options ) do |ws|

    # register client connection
    ws.onopen {
      client_id = ws.object_id
      log 'notice', 'Client connected.', client_id

      if !@clients.include? client_id
        @clients[client_id] = {
          :websocket   => ws,
          :last_ping   => Time.new,
          :error_count => 0,
        }
      end
    }

    # unregister client connection
    ws.onclose {
      client_id = ws.object_id
      log 'notice', 'Client disconnected.', client_id

      # removed from current client list
      if @clients.include? client_id
        @clients.delete client_id
      end

      Session.destory( client_id )
    }

    # manage messages
    ws.onmessage { |msg|

      client_id = ws.object_id
      log 'debug', "received message: #{ msg } ", client_id
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
        meta = {
          :msg        => msg,
          :msg_object => data,
          :timestamp  => Time.now.to_i,
        }
        @spool.push meta
      end

      # get spool messages
      if data['action'] == 'spool'
        @spool.each { |message|

          begin
            message_parsed = JSON.parse( message[:msg] )
          rescue => e
            log 'error', "can't parse spool message: #{ message }, #{ e.inspect }"
            next
          end

          # add spool attribute to push spool info to clients
          message_parsed['data']['spool'] = true
          msg = JSON.generate( message_parsed )

          # only send not already now messages
          if !data['timestamp'] || data['timestamp'] < message[:timestamp]

            # spool to recipient list
            if message[:msg_object]['recipient'] && message[:msg_object]['recipient']['user_id']
              message[:msg_object]['recipient']['user_id'].each { |user_id|
                if @clients[client_id][:session]['id'] == user_id
                  log 'notice', "send spool to (user_id=#{user_id})", client_id
                  @clients[client_id][:websocket].send( "[#{ msg }]" )
                end
              }

            # spool to every client
            else
              log 'notice', "send spool", client_id
              @clients[client_id][:websocket].send( "[#{ msg }]" )
            end

          end
        }
      end

      # get session
      if data['action'] == 'login'
        @clients[client_id][:session] = data['session']
        Session.create( client_id, data['session'], { :type => 'websocket' } )

      # remember ping, send pong back
      elsif data['action'] == 'ping'
        @clients[client_id][:last_ping] = Time.now
        @clients[client_id][:websocket].send( '[{"action":"pong"}]' )

      # broadcast
      elsif data['action'] == 'broadcast'

        # list all current clients
        client_list = Session.list
        client_list.each {|local_client_id, local_client|
          if local_client_id.to_s != client_id.to_s

            # broadcast to recipient list
            if data['recipient']
              if data['recipient'].class != Hash
                log 'error', "recipient attribute isn't a hash '#{ data['recipient'].inspect }'"
              else
                if !data['recipient'].has_key?('user_id')
                  log 'error', "need recipient.user_id attribute '#{ data['recipient'].inspect }'"
                else
                  if data['recipient']['user_id'].class != Array
                    log 'error', "recipient.user_id attribute isn't an array '#{ data['recipient']['user_id'].inspect }'"
                  else
                    data['recipient']['user_id'].each { |user_id|
                      if local_client[:user][:id].to_i == user_id.to_i
                        log 'notice', "send broadcast to (user_id=#{user_id})", local_client_id
                        if local_client[:meta][:type] == 'websocket' && @clients[ local_client_id ]
                          @clients[ local_client_id ][:websocket].send( "[#{msg}]" )
                        else
                          Session.send( local_client_id, data )
                        end
                      end
                    }
                  end
                end
              end

            # broadcast every client
            else
              log 'notice', "send broadcast", local_client_id
              if local_client[:meta][:type] == 'websocket' && @clients[ local_client_id ]
                @clients[ local_client_id ][:websocket].send( "[#{msg}]" )
              else
                Session.send( local_client_id, data )
              end
            end
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
    @clients.each { |client_id, client|
      log 'notice', 'working...', client_id
    }

    # ajax
    client_list = Session.list
    clients = 0
    client_list.each {|client_id, client|
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
    log 'debug', "checking for data to send..."
    @clients.each { |client_id, client|
      next if client[:disconnect]
      log 'debug', 'checking for data...', client_id
      begin
        queue = Session.queue( client_id )
        if queue && queue[0]
#          log "send " + queue.inspect, client_id
          log 'notice', "send data to client", client_id
          client[:websocket].send( queue.to_json )
        end
      rescue => e

        log 'error', 'problem:' + e.inspect, client_id

        # disconnect client
        client[:error_count] += 1
        if client[:error_count] > 100
          if @clients.include? client_id
            @clients.delete client_id
          end
        end
      end
    }
  }

  def check_unused_connections
    log 'notice', "check unused idle connections..."

    idle_time_in_min = 4

    # web sockets
    @clients.each { |client_id, client|
      if ( client[:last_ping] + ( 60 * idle_time_in_min ) ) < Time.now
        log 'notice', "closing idle websocket connection", client_id

        # remember to not use this connection anymore
        client[:disconnect] = true

        # try to close regular
        client[:websocket].close_websocket

        # delete sesstion from client list
        sleep 1
        @clients.delete(client_id)
      end
    }

    # ajax
    clients = Session.list
    clients.each { |client_id, client|
      next if client[:meta][:type] == 'websocket'
      if ( client[:meta][:last_ping].to_i + ( 60 * idle_time_in_min ) ) < Time.now.to_i
        log 'notice', "closing idle ajax connection", client_id
        Session.destory( client_id )
      end
    }
  end

  def log( level, data, client_id = '-' )
    if !@options[:v]
      return if level == 'debug'
    end
    puts "#{Time.now}:client(#{ client_id }) #{ data }"
#    puts "#{Time.now}:#{ level }:client(#{ client_id }) #{ data }"
  end

}
