$LOAD_PATH << './lib'
require 'rubygems'
require 'eventmachine'
require 'em-websocket'
require 'json'
require 'fileutils'
require 'web_socket'
require 'optparse'

# Look for -o with argument, and -I and -D boolean arguments
options = {
  :p => 6042,
  :b => '0.0.0.0',
}
OptionParser.new do |opts|
  opts.banner = "Usage: websocket-server.rb [options]"

  opts.on("-p", "--port [OPT]", "port of websocket server") do |p|
    options[:p] = p
  end
  opts.on("-b", "--bind [OPT]", "bind address") do |b|
    options[:b] = b
  end
end.parse!

puts "Starting websocket server on #{ options[:b] }:#{ options[:p] }"

@clients = {}
EventMachine.run {
  EventMachine::WebSocket.start( :host => options[:b], :port => options[:p] ) do |ws|

    # register client connection
    ws.onopen {
      client_id = ws.object_id
      puts 'Client ' + client_id.to_s + ' connected'

      if !@clients.include? client_id
        @clients[client_id] = {
          :websocket => ws,
        } 
      end
    }

    # unregister client connection
    ws.onclose {
      client_id = ws.object_id
      puts 'Client ' + client_id.to_s + ' disconnected'
      
      if @clients.include? client_id
        @clients.delete client_id
      end
      Session.destory( client_id )
    }

    # manage messages
    ws.onmessage { |msg|

      client_id = ws.object_id
      puts 'From Client ' + client_id.to_s + ' received message: ' + msg
      data = JSON.parse(msg)

      # get session
      if data['action'] == 'login'
        @clients[client_id][:session] = data['session']
        Session.create( client_id, data['session'] )
      end 
    }
  end

  EventMachine.add_periodic_timer(0.4) {
#    puts "loop"
    @clients.each { |client_id, client|
#      puts 'checking client...' + client_id.to_s
      begin
        queue = Session.queue( client_id )
        if queue && queue[0]
          puts "send to #{client_id} " + queue.inspect
          client[:websocket].send( queue.to_json )
        end
      rescue
        puts 'problem'
      end
    }
  }

}
