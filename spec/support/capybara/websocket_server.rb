# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|
  config.around(:each, type: :system) do |example|

    server_required = example.metadata.fetch(:websocket, true)

    if server_required
      port = ENV['WS_PORT'] || 6042

      ensure_port_available!(port)

      websocket_server = Thread.new do
        WebsocketServer.run(
          p:           port,
          b:           '0.0.0.0',
          s:           true,
          v:           false,
          d:           false,
          tls_options: {
            private_key_file: "#{Dir.home}/.localhost/localhost.key",
            cert_chain_file:  "#{Dir.home}/.localhost/localhost.crt",
          }
        )
      end
    end

    example.run

    next if !server_required

    # returns immediately and thread may be still shutting down
    EventMachine.stop_event_loop

    # give thread time to terminate
    sleep 0.01 while websocket_server.status
  rescue => e
    # Handle any errors occuring within this hook, for example Net::ReadTimeout errors of the WS server.
    #   Otherwise, they would not cause the retry to kick in, but abort the process.
    example.example.set_exception(e)
  end

  def ensure_port_available!(port)
    %w[0.0.0.0 127.0.0.1].each do |host|
      TCPServer.new(host, port).close # release port immediately
    end
  rescue Errno::EADDRINUSE
    raise "Couldn't start WebSocket server. Maybe another websocket server process is already running?"
  end
end
