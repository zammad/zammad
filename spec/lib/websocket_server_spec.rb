# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe WebsocketServer do
  describe '.run' do
    let(:port) do
      TCPServer.new('127.0.0.1', 0).then do |socket|
        socket.local_address.ip_port.tap { socket.close }
      end
    end
    let(:options) { { p: port, b: '127.0.0.1', s: false, v: false, d: false } }

    def stop_server(thread)
      EventMachine.stop_event_loop if thread.status
      thread.join(5)
    end

    def handshake_response
      TCPSocket.new('127.0.0.1', port).then do |socket|
        socket.write "GET /ws HTTP/1.1\r\nHost: 127.0.0.1:#{port}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: #{SecureRandom.base64(16)}\r\nSec-WebSocket-Version: 13\r\n\r\n"
        socket.readpartial(4096).tap { socket.close }
      end
    end

    # EventMachine resolves the bind address itself with AI_ADDRCONFIG, which fails for 127.0.0.1 on IPv6-only hosts (#6536).
    it 'binds the listen socket in Ruby and serves websocket handshakes through it', :aggregate_failures do
      allow(EventMachine).to receive(:attach_server).and_call_original
      allow(EventMachine).to receive(:start_server).and_call_original

      thread = Thread.new { described_class.run(options) }

      begin
        Timeout.timeout(10) do
          sleep 0.05 while thread.status && !EventMachine.reactor_running?
        end

        expect(handshake_response).to start_with('HTTP/1.1 101 Switching Protocols')
        expect(EventMachine).to have_received(:attach_server)
          .with(an_instance_of(TCPServer), EventMachine::WebSocket::Connection, hash_including(host: '127.0.0.1', port: port))
        expect(EventMachine).not_to have_received(:start_server)
      ensure
        stop_server(thread)
      end
    end

    it 'fails with the address and port when the port is already in use' do
      blocker = TCPServer.new('127.0.0.1', port)

      expect { described_class.run(options) }
        .to raise_error(Errno::EADDRINUSE, %r{127\.0\.0\.1.*#{port}})
    ensure
      blocker&.close
    end
  end
end
