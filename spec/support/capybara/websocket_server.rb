# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The hostname and the port of this run are resolved there - recomputing them
#   here would let the two files disagree (e.g. for CAPYBARA_HOSTNAME setups
#   like .devcontainer/with-selenium).
require_relative 'driven_by'

RSpec.configure do |config|

  localhost_authority = Localhost::Authority.new(CAPYBARA_HOSTNAME, issuer: nil)
  localhost_authority.save # make sure the certificate is created

  config.around(:each, type: :system) do |example|

    server_required = example.metadata.fetch(:websocket, true)

    if server_required
      ensure_port_available!(WS_PORT)

      ws_thread = Thread.new do
        WebsocketServer.run(
          p:           WS_PORT,
          b:           '0.0.0.0',
          s:           true,
          v:           false,
          d:           false,
          tls_options: {
            private_key_file: localhost_authority.key_path,
            cert_chain_file:  localhost_authority.certificate_path,
          }
        )
      end

      # The EventMachine reactor above needs a moment to actually bind the port.
      #   Wait for it to become reachable before running the example, otherwise the
      #   browser's very first chat connection attempt may race the server startup.
      wait_for_websocket_server!(WS_PORT)
    end

    example.run
  rescue => e
    # Handle any errors occuring within this hook, for example Net::ReadTimeout errors of the WS server.
    #   Otherwise, they would not cause the retry to kick in, but abort the process.
    example.example.set_exception(e)
  ensure
    stop_websocket_server(ws_thread) if server_required

    # The websocket server is stopped without running its disconnect handling, so the
    #   session entries of this example would leak into the following examples and
    #   confuse those which rely on Sessions.sessions.
    Sessions.sessions.each { |client_id| Sessions.destroy(client_id) }
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
    raise "Couldn't start WebSocket server on port #{port}. Maybe another websocket server process is already running? Set WS_PORT to a free port to run this suite alongside it."
  end

  def wait_for_websocket_server!(port, timeout: 10)
    deadline = Time.current + timeout
    begin
      TCPSocket.new('127.0.0.1', port).close
    rescue Errno::ECONNREFUSED
      raise "WebSocket server did not start listening on port #{port} within #{timeout} seconds" if Time.current >= deadline

      sleep 0.05
      retry
    end
  end
end
