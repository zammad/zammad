# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Store::Redis do
  let(:instance) { described_class.new }

  describe '#destroy' do
    let(:client_id) { 'test_client_id' }

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
  end
end
