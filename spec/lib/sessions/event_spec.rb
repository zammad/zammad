# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions::Event do
  describe 'database connection requirement flag' do
    it 'is not set for the event base class' do
      expect(Sessions::Event::Base.instance_variable_get(:@database_connection)).to be_nil
    end

    it 'is set for chat events' do
      expect(Sessions::Event::ChatBase.instance_variable_get(:@database_connection)).to be(true)
    end

    it 'is set for chat agent status events' do
      expect(Sessions::Event::ChatStatusAgent.instance_variable_get(:@database_connection)).to be(true)
    end
  end

  # check if db connection is available for chat events
  # see: https://github.com/zammad/zammad/issues/2353
  describe '.run database connection handling' do
    let(:websocket) do
      Class.new do
        def send(msg) # rubocop:disable Zammad/ForbidDefSend
          Rails.logger.info "WS send: #{msg}"
        end
      end.new
    end

    def run_event(event, clients)
      described_class.run(
        event:     event,
        payload:   {},
        session:   {},
        remote_ip: '127.0.0.1',
        client_id: '123',
        clients:   clients,
        options:   {},
      )
    end

    context 'with a websocket connection and no established database connection' do
      # Disable transactional tests because the examples remove
      # and re-establish the database connection.
      self.use_transactional_tests = false

      before do
        ActiveRecord::Base.remove_connection
      end

      after do
        ActiveRecord::Base.establish_connection
      end

      it 'removes the database connection again after a login event', :aggregate_failures do
        message = run_event('login', { '123' => { websocket: websocket } })

        expect(message).to be(false)
        expect { User.first }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end

      it 'removes the database connection again after a chat event', :aggregate_failures do
        message = run_event('chat_status_customer', { '123' => websocket })

        expect(message[:event]).to eq('chat_error')
        expect { User.first }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      end
    end

    context 'with ajax long polling' do
      it 'keeps the database connection after a login event', :aggregate_failures do
        message = run_event('login', {})

        expect(message).to be(false)
        expect { User.first }.not_to raise_error
      end

      it 'keeps the database connection after a chat event', :aggregate_failures do
        message = run_event('chat_status_customer', {})

        expect(message[:event]).to eq('chat_error')
        expect { User.first }.not_to raise_error
      end
    end
  end
end
