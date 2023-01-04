# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, type: :system) do |example|

    # Temporary Hack: skip tests if ENABLE_EXPERIMENTAL_MOBILE_FRONTEND is not set.
    # TODO: Remove when this switch is not needed any more.
    if example.metadata[:app] == :mobile && ENV['ENABLE_EXPERIMENTAL_MOBILE_FRONTEND'] != 'true'
      next
    end

    server_required = example.metadata.fetch(:websocket, true)

    if server_required
      port = ENV['WS_PORT'] || 6042

      ensure_port_available!(port)

      websocket_server = Thread.new do
        WebsocketServer.run(
          p: port,
          b: '0.0.0.0',
          s: false,
          v: false,
          d: false,
        )
      end
    end

    example.run

    next if !server_required

    # returns immediately and thread may be still shutting down
    EventMachine.stop_event_loop

    # give thread time to terminate
    sleep 0.01 while websocket_server.status
  end

  def ensure_port_available!(port)
    %w[0.0.0.0 127.0.0.1].each do |host|
      TCPServer.new(host, port).close # release port immediately
    end
  rescue Errno::EADDRINUSE
    raise "Couldn't start WebSocket server. Maybe another websocket server process is already running?"
  end
end
