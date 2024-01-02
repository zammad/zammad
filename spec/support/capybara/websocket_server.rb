# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.configure do |config|

  hostname = ENV['CI'].present? ? 'build' : 'localhost'
  localhost_autority = Localhost::Authority.fetch(hostname)

  config.around(:each, type: :system) do |example|

    server_required = example.metadata.fetch(:websocket, true)

    if server_required
      port = ENV['WS_PORT'] || 6042

      ensure_port_available!(port)

      ws_thread = Thread.new do
        WebsocketServer.run(
          p:           port,
          b:           '0.0.0.0',
          s:           true,
          v:           false,
          d:           false,
          tls_options: {
            private_key_file: localhost_autority.key_path,
            cert_chain_file:  localhost_autority.certificate_path,
          }
        )
      end
    end

    example.run
  rescue => e
    # Handle any errors occuring within this hook, for example Net::ReadTimeout errors of the WS server.
    #   Otherwise, they would not cause the retry to kick in, but abort the process.
    example.example.set_exception(e)
  ensure
    stop_websocket_server(ws_thread) if server_required
  end

  def stop_websocket_server(ws_thread)
    # returns immediately and thread may be still shutting down
    EventMachine.stop_event_loop if ws_thread.status

    # give thread time to terminate
    sleep 0.01 while ws_thread.status
  rescue => e
    Rails.logger.error "Error occurred during web socket server shutdown: #{e}"
    $stderr.puts "Error occurred during web socket server shutdown: #{e}" # rubocop:disable Style/StderrPuts
    # Ignore this error and continue, to allow for the rspec-retry mechanism to work.
  end

  def ensure_port_available!(port)
    %w[0.0.0.0 127.0.0.1].each do |host|
      TCPServer.new(host, port).close # release port immediately
    end
  rescue Errno::EADDRINUSE
    raise "Couldn't start WebSocket server. Maybe another websocket server process is already running?"
  end
end
