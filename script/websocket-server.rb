$LOAD_PATH << './lib'
require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'web_socket'
require 'optparse'

# Look for -o with argument, and -I and -D boolean arguments
@options = {
  :p => 6042,
  :b => '0.0.0.0',
  :s => false,
  :d => false,
  :k => '/path/to/server.key',
  :c => '/path/to/server.crt',
}
tls_options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: websocket-server.rb [options]"

  opts.on("-d", "--debug", "enable debug messages") do |d|
    @options[:d] = d
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
  opts.on("-k", "--private-key [OPT]", "/path/to/server.key for secure connections") do |k|
    tls_options[:private_key_file] = k
  end
  opts.on("-c", "--certificate [OPT]", "/path/to/server.crt for secure connections") do |c|
    tls_options[:cert_chain_file] = c
  end
end.parse!

puts "Starting websocket server on #{ @options[:b] }:#{ @options[:p] } (secure:#{ @options[:s].to_s })"
#puts options.inspect

@clients = {}
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
        log 'error', "can't parse message: #{ msg }, #{ e.inspect}", client_id
        next
      end

      # check if connection already exists
      next if !@clients[client_id]

      # get session
      if data['action'] == 'login'
        @clients[client_id][:session] = data['session']
        Session.create( client_id, data['session'] )

      # remember ping, send pong back
      elsif data['action'] == 'ping'
        @clients[client_id][:last_ping] = Time.now
        @clients[client_id][:websocket].send( '[{"action":"pong"}]' )

      # broadcast
      elsif data['action'] == 'broadcast'
        @clients.each { |local_client_id, local_client|
          if local_client_id != client_id
            local_client[:websocket].send( "[#{msg}]" )
          end
        }
      end
    }
  end

  # check open unused connections, kick all connection without activitie in the last 5 minutes
  EventMachine.add_periodic_timer(120) {
    log 'notice', "check unused idle connections..."
    @clients.each { |client_id, client|
      if ( client[:last_ping] + ( 60 * 4 ) ) < Time.now
        log 'notice', "closing idle connection", client_id

        # remember to not use this connection anymore
        client[:disconnect] = true

        # try to close regular
        client[:websocket].close_websocket

        # delete sesstion from client list
        sleep 1
        @clients.delete(client_id)
      end
    }
  }

  EventMachine.add_periodic_timer(20) {
    log 'notice', "Status: clients: #{ @clients.size }"
    @clients.each { |client_id, client|
      log 'notice', 'working...', client_id
    }
  }

  EventMachine.add_periodic_timer(0.2) {
    next if @clients.size == 0
    log 'debug', "checking for data..."
    @clients.each { |client_id, client|
      next if client[:disconnect]
      log 'debug', 'checking for data...', client_id
      begin
        queue = Session.queue( client_id )
        if queue && queue[0]
#          log "send " + queue.inspect, client_id
          log 'debug', "send data to client", client_id
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
  
  def log( level, data, client_id = '-' )
    if !@options[:d]
      return if level == 'debug'
    end
    puts "#{Time.now}:client(#{ client_id }) #{ data }"
#    puts "#{Time.now}:#{ level }:client(#{ client_id }) #{ data }"
  end

}
