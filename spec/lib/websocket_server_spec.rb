# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe WebsocketServer do
  describe '.onmessage' do
    let(:websocket) { instance_double(EventMachine::WebSocket::Connection) }
    let(:client_id) { websocket.object_id.to_s }

    before do
      described_class.instance_variable_set(:@clients, {
                                              client_id => {
                                                websocket: websocket,
                                                last_ping: 0,
                                                session:   {},
                                                headers:   {},
                                              }
                                            })
      described_class.instance_variable_set(:@options, { v: false, d: false })
      Sessions.create(client_id, {}, { type: 'websocket' })
    end

    after do
      Sessions.destroy(client_id)
      described_class.instance_variable_set(:@clients, nil)
    end

    context 'with a message that is a JSON object' do
      it 'executes the event' do
        allow(Sessions::Event).to receive(:run).and_return(nil)

        described_class.onmessage(websocket, { event: 'ping' }.to_json)

        expect(Sessions::Event).to have_received(:run).with(hash_including(event: 'ping', client_id: client_id))
      end
    end

    context 'with a message that is not a JSON object' do
      it 'ignores a JSON array' do
        expect { described_class.onmessage(websocket, [{ event: 'ping' }].to_json) }.not_to raise_error
      end

      it 'ignores a JSON number' do
        expect { described_class.onmessage(websocket, '1') }.not_to raise_error
      end

      it 'ignores a JSON float' do
        expect { described_class.onmessage(websocket, '1.5') }.not_to raise_error
      end

      it 'ignores a JSON null' do
        expect { described_class.onmessage(websocket, 'null') }.not_to raise_error
      end

      it 'ignores a JSON boolean' do
        expect { described_class.onmessage(websocket, 'true') }.not_to raise_error
      end

      it 'ignores a JSON string' do
        expect { described_class.onmessage(websocket, '"ping"') }.not_to raise_error
      end

      it 'ignores invalid JSON' do
        expect { described_class.onmessage(websocket, '{') }.not_to raise_error
      end
    end
  end
end
