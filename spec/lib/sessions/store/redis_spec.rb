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

  describe '#get_many' do
    let(:redis) { instance.instance_variable_get(:@redis) }

    before do
      instance.create('a1', { user: { 'id' => 1 }, meta: { type: 'websocket' } }.to_json)
      instance.create('a2', { user: {}, meta: { type: 'ajax' } }.to_json)
      instance.create('a3', { user: { 'id' => 3 }, meta: { type: 'websocket' } }.to_json)
      redis.del("#{described_class::SESSIONS_KEY}/a2")
      allow(redis).to receive(:mget).and_call_original
    end

    after do
      %w[a1 a2 a3].each { instance.destroy(it) }
    end

    it 'returns the sessions by client id, like #get' do
      expect(instance.get_many(%w[a3 a1])).to eq('a3' => instance.get('a3'), 'a1' => instance.get('a1'))
    end

    it 'removes a session whose value is missing' do
      expect { instance.get_many(%w[a1 a2 a3]) }
        .to change { instance.sessions.include?('a2') }
        .to(false)
    end

    it 'leaves out a session whose value is missing' do
      expect(instance.get_many(%w[a1 a2 a3]).keys).to eq(%w[a1 a3])
    end

    it 'reads the sessions in slices' do
      stub_const("#{described_class}::GET_MANY_SLICE_SIZE", 2)

      instance.get_many(%w[a1 a2 a3])

      expect(redis).to have_received(:mget).twice
    end

    it 'does not ask Redis without client ids', :aggregate_failures do
      expect(instance.get_many([])).to eq({})
      expect(redis).not_to have_received(:mget)
    end
  end

  describe '#send_data_many' do
    let(:redis) { instance.instance_variable_get(:@redis) }

    before do
      %w[a1 a2].each { instance.create(it, { user: { 'id' => 1 }, meta: {} }.to_json) }
      allow(redis).to receive(:pipelined).and_call_original
    end

    after do
      %w[a1 a2].each { instance.destroy(it) }
    end

    def ttl(client_id)
      redis.ttl("#{described_class::MESSAGES_KEY}/#{client_id}")
    end

    it 'keeps the order of the messages per client', :aggregate_failures do
      instance.send_data_many([['a1', { event: 'one' }], ['a2', { event: 'one' }], ['a1', { event: 'two' }], ['a2', { event: 'three' }]])

      expect(instance.queue('a1').pluck('event')).to eq(%w[one two])
      expect(instance.queue('a2').pluck('event')).to eq(%w[one three])
    end

    it 'lets a new queue expire after an hour' do
      instance.send_data_many([['a1', { event: 'one' }], ['a1', { event: 'two' }]])

      expect(ttl('a1')).to be_between(1, 1.hour.to_i)
    end

    it 'keeps the expiry of an existing queue, like #send_data' do
      instance.send_data('a1', { event: 'one' })
      redis.expire("#{described_class::MESSAGES_KEY}/a1", 100)

      instance.send_data_many([['a1', { event: 'two' }]])

      expect(ttl('a1')).to be_between(1, 100)
    end

    it 'pushes all messages in one pipeline and sets the expiry in a second one' do
      instance.send_data_many([['a1', { event: 'one' }], ['a2', { event: 'one' }], ['a1', { event: 'two' }]])

      expect(redis).to have_received(:pipelined).twice
    end

    it 'pushes in slices, keeping the order and the expiry', :aggregate_failures do
      stub_const("#{described_class}::PIPELINE_SLICE_SIZE", 2)

      instance.send_data_many([['a1', { event: 'one' }], ['a2', { event: 'one' }], ['a1', { event: 'two' }]])

      expect(redis).to have_received(:pipelined).exactly(3).times
      expect([ttl('a1'), ttl('a2')]).to all(be_between(1, 1.hour.to_i))
      expect(instance.queue('a1').pluck('event')).to eq(%w[one two])
    end

    it 'has set the expiry of a slice before the next slice is pushed', :aggregate_failures do
      stub_const("#{described_class}::PIPELINE_SLICE_SIZE", 2)
      calls = 0
      allow(redis).to receive(:pipelined).and_wrap_original do |original, &block|
        raise Redis::ConnectionError if (calls += 1) == 3

        original.call(&block)
      end

      expect { instance.send_data_many([['a1', { event: 'one' }], ['a2', { event: 'one' }], ['a1', { event: 'two' }]]) }
        .to raise_error(Redis::ConnectionError)
      expect([ttl('a1'), ttl('a2')]).to all(be_between(1, 1.hour.to_i))
    end

    it 'does not ask Redis without messages' do
      instance.send_data_many([])

      expect(redis).not_to have_received(:pipelined)
    end
  end

  describe '#clear_queue' do
    let(:client_id) { 'test_client_id' }

    before do
      instance.create(client_id, { user: { 'id' => 1 }, meta: {} }.to_json)
      instance.send_data(client_id, { event: 'test' })
    end

    after do
      instance.destroy(client_id)
    end

    it 'removes the queued messages' do
      instance.clear_queue(client_id)

      expect(instance.queue(client_id)).to be_empty
    end

    it 'keeps the session' do
      instance.clear_queue(client_id)

      expect(instance.get(client_id)).to include(user: { 'id' => 1 })
    end
  end
end
