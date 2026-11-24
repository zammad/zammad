# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PushMessages do
  describe '.deliver' do
    let(:sessions) { { 'a1' => { 'id' => 11 }, 'b1' => { 'id' => 12 }, 'c1' => {} } }
    let(:store)    { Sessions.instance_variable_get(:@store) }

    let(:messages) do
      described_class.init
      described_class.send({ message: { event: 'one' }, type: 'authenticated' })
      described_class.send_to(11, { event: 'two' })
      described_class.send({ message: { event: 'three' }, type: 'public', current_user_id: 12 })
      described_class.send_to(12, { event: 'four' })
      described_class.flush
    end

    before do
      Sessions.cleanup
      sessions.each do |client_id, user|
        Sessions.create(client_id, user, { type: 'websocket' })
        Sessions.queue(client_id)
      end
    end

    after do
      Sessions.cleanup
    end

    it 'gives every client its messages in the buffered order' do
      described_class.deliver(messages)

      expect(sessions.keys.index_with { Sessions.queue(it).pluck('event') })
        .to eq('a1' => %w[one two three], 'b1' => %w[one four], 'c1' => ['three'])
    end

    it 'reads the sessions once and writes all messages at once', :aggregate_failures do
      allow(store).to receive(:get_many).and_call_original
      allow(store).to receive(:send_data_many).and_call_original

      described_class.deliver(messages)

      expect(store).to have_received(:get_many).once
      expect(store).to have_received(:send_data_many).once
    end

    context 'with the Redis store' do
      let(:store) { Sessions::Store::Redis.new }
      let(:redis) { store.instance_variable_get(:@redis) }

      around do |example|
        original_store = Sessions.instance_variable_get(:@store)
        Sessions.instance_variable_set(:@store, store)
        example.run
      ensure
        Sessions.instance_variable_set(:@store, original_store)
      end

      it 'reads all sessions with one MGET and pushes all messages in one pipeline', :aggregate_failures do
        %i[smembers mget pipelined get rpush].each { allow(redis).to receive(it).and_call_original }

        described_class.deliver(messages)

        expect(redis).to have_received(:smembers).once
        expect(redis).to have_received(:mget).once
        expect(redis).to have_received(:pipelined).twice
        expect(redis).not_to have_received(:get)
        expect(redis).not_to have_received(:rpush)
      end
    end

    it 'does nothing without messages' do
      allow(store).to receive(:get_many)

      described_class.deliver([])

      expect(store).not_to have_received(:get_many)
    end
  end
end
