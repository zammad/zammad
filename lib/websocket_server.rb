# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class WebsocketServer

  cattr_reader :clients, :options

  def self.run(options)
    @options = options
    @clients = {}

    Rails.configuration.interface = 'websocket'
    EventMachine.run do
      EventMachine::WebSocket.start( host: @options[:b], port: @options[:p], secure: @options[:s], tls_options: @options[:tls_options] ) do |ws|

        # register client connection
        ws.onopen do |handshake|
          WebsocketServer.onopen(ws, handshake)
        end

        # unregister client connection
        ws.onclose do
          WebsocketServer.onclose(ws)
        end

        # manage messages
        ws.onmessage do |msg|
          WebsocketServer.onmessage(ws, msg)
        end
      end

      # check unused connections
      EventMachine.add_timer(0.5) do
        WebsocketServer.check_unused_connections
      end

      # check open unused connections, kick all connection without activity in the last 2 minutes
      EventMachine.add_periodic_timer(120) do
        WebsocketServer.check_unused_connections
      end

      EventMachine.add_periodic_timer(20) do
        WebsocketServer.log_status
      end

      EventMachine.add_periodic_timer(0.4) do
        WebsocketServer.send_to_client
      end
    end
  end

  def self.onopen(websocket, handshake)
    headers = handshake.headers
    client_id = websocket.object_id.to_s
    log 'info', 'Client connected.', client_id
    Sessions.create( client_id, {}, { type: 'websocket' } )

    return if @clients.include? client_id

    @clients[client_id] = {
      websocket:   websocket,
      last_ping:   Time.now.utc.to_i,
      error_count: 0,
      headers:     headers,
    }
  end

  def self.onclose(websocket)
    client_id = websocket.object_id.to_s
    log 'info', 'Client disconnected.', client_id

    # removed from current client list
    if @clients.include? client_id
      @clients.delete client_id
    end

    Sessions.destroy(client_id)
  end

  def self.onmessage(websocket, msg)
    client_id = websocket.object_id.to_s
    log 'debug', "received: #{msg} ", client_id
    begin
      data = JSON.parse(msg)
    rescue => e
      log 'error', "can't parse message: #{msg}, #{e.inspect}", client_id
      return
    end

    # check if connection not already exists
    return if !@clients[client_id]

    Sessions.touch(client_id) # rubocop:disable Rails/SkipsModelValidations
    @clients[client_id][:last_ping] = Time.now.utc.to_i

    # spool messages for new connects
    if data['spool']
      Sessions.spool_create(data)
    end

    if data['event']
      log 'debug', "execute event '#{data['event']}'", client_id
      message = Sessions::Event.run(
        event:     data['event'],
        payload:   data,
        session:   @clients[client_id][:session],
        headers:   @clients[client_id][:headers],
        client_id: client_id,
        clients:   @clients,
        options:   @options,
      )
      if message
        websocket_send(client_id, message)
      end
    else
      log 'error', "unknown message '#{data.inspect}'", client_id
    end
  end

  def self.websocket_send(client_id, data)
    msg = if data.instance_of?(Array)
            data.to_json
          else
            "[#{data.to_json}]"
          end
    log 'debug', "send #{msg}", client_id
    if !@clients[client_id]
      log 'error', "no such @clients for #{client_id}", client_id
      return
    end
    @clients[client_id][:websocket].send(msg)
  end

  def self.check_unused_connections
    log 'info', 'check unused idle connections...'

    idle_time_in_sec = 4 * 60

    # close unused web socket sessions
    @clients.each do |client_id, client|

      next if ( client[:last_ping].to_i + idle_time_in_sec ) >= Time.now.utc.to_i

      log 'info', 'closing idle websocket connection', client_id

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
      log 'info', 'closing idle long polling connection', client_id
    end
  end

  def self.send_to_client
    return if @clients.size.zero?

    #log 'debug', 'checking for data to send...'
    @clients.each do |client_id, client|
      next if client[:disconnect]

      log 'debug', 'checking for data...', client_id
      begin
        queue = Sessions.queue(client_id)
        next if queue.blank?

        log 'info', 'send data to client', client_id
        websocket_send(client_id, queue)
      rescue => e
        log 'error', "problem:#{e.inspect}", client_id

        # disconnect client
        client[:error_count] += 1
        if client[:error_count] > 20 && @clients.include?(client_id)
          @clients.delete client_id
        end
      end
    end
  end

  def self.log_status
    # websocket
    log 'info', "Status: websocket clients: #{@clients.size}"
    @clients.each_key do |client_id|
      log 'info', 'working...', client_id
    end

    # ajax
    client_list = Sessions.list
    clients = 0
    client_list.each_value do |client|
      next if client[:meta][:type] == 'websocket'

      clients = clients + 1
    end
    log 'info', "Status: ajax clients: #{clients}"
    client_list.each do |client_id, client|
      next if client[:meta][:type] == 'websocket'

      log 'info', 'working...', client_id
    end
  end

  def self.log(level, data, client_id = '-')
    return if !@options[:v] && level == 'debug'

    puts "#{Time.now.utc.iso8601}:client(#{client_id}) #{data}" # rubocop:disable Rails/Output
    #puts "#{Time.now.utc.iso8601}:#{ level }:client(#{ client_id }) #{ data }"
  end
end
