# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Store::File do
  let(:instance) { described_class.new }

  describe '#destroy' do
    let(:client_id) { 'abc123' }

    context 'when using single-worker sessions' do
      before do
        instance.create(client_id, 'test_data')
      end

      it 'destroys the session' do
        expect { instance.destroy(client_id) }
          .to change { instance.session_exists?(client_id) }
          .to(false)
      end
    end

    context 'when using multi-worker sessions' do
      let(:node) { 'node1' }

      before do
        instance.create_node_session(node, client_id, 'test_data')
      end

      def count_node_sessions
        i = 0

        instance.each_session_by_node(node) { |_client_id| i += 1 }

        i
      end

      it 'destroys the session' do
        expect { instance.destroy(client_id) }
          .to change { count_node_sessions }
          .by(-1)
      end
    end

    context 'when client_id contains path traversal' do
      let(:traversal_id) { '../path_traversal_test' }

      it 'raises ArgumentError' do
        expect { instance.destroy(traversal_id) }
          .to raise_error(ArgumentError, %r{Invalid client_id})
      end
    end
  end

  describe '#get' do
    context 'when client_id contains path traversal' do
      it 'raises ArgumentError' do
        expect { instance.get('../etc/passwd') }
          .to raise_error(ArgumentError, %r{Invalid client_id})
      end
    end
  end

  describe '#create' do
    context 'when client_id contains path traversal' do
      it 'raises ArgumentError' do
        expect { instance.create('../malicious', '{}') }
          .to raise_error(ArgumentError, %r{Invalid client_id})
      end
    end
  end

  describe '#send_data' do
    let(:client_id) { 'abc123' }
    let(:data)      { { event: 'test', payload: 'hello' } }

    context 'when session directory exists' do
      before do
        instance.create(client_id, '{}')
      end

      after do
        instance.destroy(client_id)
      end

      it 'returns true' do
        expect(instance.send_data(client_id, data)).to be(true)
      end

      it 'creates a message file' do
        instance.send_data(client_id, data)

        message_files = Dir.glob("#{instance.send(:safe_session_path, client_id)}/send-*")
        expect(message_files).not_to be_empty
      end

      it 'writes the correct JSON content' do
        instance.send_data(client_id, data)

        message_files = Dir.glob("#{instance.send(:safe_session_path, client_id)}/send-*")
        content = JSON.parse(File.read(message_files.first))
        expect(content).to include('event' => 'test')
      end
    end

    context 'when session directory does not exist' do
      it 'returns false' do
        expect(instance.send_data(client_id, data)).to be(false)
      end
    end

    context 'when client_id contains path traversal' do
      it 'raises ArgumentError' do
        expect { instance.send_data('../malicious', data) }
          .to raise_error(ArgumentError, %r{Invalid client_id})
      end
    end
  end

  describe '#new_message_filename_for' do
    let(:client_id) { 'abc123' }

    context 'when session directory exists' do
      before do
        instance.create(client_id, '{}')
      end

      after do
        instance.destroy(client_id)
      end

      it 'returns a path starting with send-' do
        result = instance.send(:new_message_filename_for, client_id)
        expect(result).to include('/send-')
      end
    end

    context 'when session directory does not exist' do
      it 'returns nil' do
        expect(instance.send(:new_message_filename_for, client_id)).to be_nil
      end
    end

    context 'when client_id contains path traversal' do
      it 'raises ArgumentError' do
        expect { instance.send(:new_message_filename_for, '../malicious') }
          .to raise_error(ArgumentError, %r{Invalid client_id})
      end
    end
  end
end
