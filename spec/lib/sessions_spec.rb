# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sessions do
  describe '.valid_client_id?' do
    it 'accepts a standard UUID' do
      expect(described_class.valid_client_id?(SecureRandom.uuid)).to be(true)
    end

    it 'accepts hex-only string' do
      expect(described_class.valid_client_id?('abc123def456')).to be(true)
    end

    it 'accepts numeric object_id style string' do
      expect(described_class.valid_client_id?('123456')).to be(true)
    end

    it 'rejects path traversal sequences' do
      expect(described_class.valid_client_id?('../etc/passwd')).to be(false)
    end

    it 'rejects dot-dot at start' do
      expect(described_class.valid_client_id?('..')).to be(false)
    end

    it 'rejects slashes' do
      expect(described_class.valid_client_id?('foo/bar')).to be(false)
    end

    it 'rejects backslashes' do
      expect(described_class.valid_client_id?('foo\\bar')).to be(false)
    end

    it 'rejects null bytes' do
      expect(described_class.valid_client_id?("abc\x00def")).to be(false)
    end

    it 'rejects empty string' do
      expect(described_class.valid_client_id?('')).to be(false)
    end

    it 'rejects nil' do
      expect(described_class.valid_client_id?(nil)).to be(false)
    end

    it 'rejects asterisk' do
      expect(described_class.valid_client_id?('*')).to be(false)
    end

    it 'rejects square brackets' do
      expect(described_class.valid_client_id?('test[0]')).to be(false)
    end

    it 'rejects question mark' do
      expect(described_class.valid_client_id?('test?')).to be(false)
    end

    it 'rejects uppercase letters' do
      expect(described_class.valid_client_id?('ABC123')).to be(false)
    end

    it 'rejects spaces' do
      expect(described_class.valid_client_id?('abc 123')).to be(false)
    end

    it 'rejects underscores' do
      expect(described_class.valid_client_id?('customer_session_id')).to be(false)
    end
  end

  describe '.get' do
    it 'returns nil for invalid client_id' do
      expect(described_class.get('../malicious')).to be_nil
    end
  end

  describe '.destroy' do
    it 'returns nil for invalid client_id' do
      expect(described_class.destroy('../malicious')).to be_nil
    end
  end

  describe '.create' do
    it 'returns nil for invalid client_id' do
      expect(described_class.create('../malicious', {}, { type: 'ajax' })).to be_nil
    end

    context 'when the session exists already' do
      let(:client_id) { '190385' }
      let(:message)   { { 'event' => 'ticket_overview_list', 'data' => {} } }

      before do
        described_class.create(client_id, { 'id' => 1 }, { type: 'websocket' })
        described_class.queue(client_id)
        described_class.send(client_id, message)
      end

      after do
        described_class.destroy(client_id)
      end

      def events
        described_class.queue(client_id).pluck('event')
      end

      it 'drops queued messages on logout' do
        described_class.create(client_id, {}, { type: 'websocket' })

        expect(events).to be_empty
      end

      it 'drops queued messages when another user logs in' do
        described_class.create(client_id, { 'id' => 2 }, { type: 'websocket' })

        expect(events).to eq(['ws:login'])
      end

      it 'drops queued messages when the session is switched to another user' do
        described_class.create(client_id, { 'id' => 1, 'switched_from_user_id' => 2 }, { type: 'websocket' })

        expect(events).to eq(['ws:login'])
      end

      it 'drops queued messages when a session without a stored user logs in' do
        described_class.instance_variable_get(:@store).create(client_id, { user: nil, meta: {} }.to_json)
        described_class.create(client_id, { 'id' => 1 }, { type: 'websocket' })

        expect(events).to eq(['ws:login'])
      end

      it 'keeps queued messages when the same user logs in again' do
        described_class.create(client_id, { 'id' => 1 }, { type: 'websocket' })

        expect(events).to eq(%w[ticket_overview_list ws:login])
      end
    end
  end

  describe '.touch' do
    it 'returns false for invalid client_id' do
      expect(described_class.touch('../malicious')).to be(false)
    end
  end

  describe '.send' do
    it 'returns false for invalid client_id' do
      expect(described_class.send(:'../malicious', { event: 'test' })).to be(false)
    end
  end

  describe 'delivering messages' do
    let(:sessions) { { 'a1' => { 'id' => 11 }, 'a2' => { 'id' => 11 }, 'b1' => { 'id' => 12 }, 'c1' => {} } }
    let(:store)    { described_class.instance_variable_get(:@store) }

    before do
      described_class.cleanup
      sessions.each do |client_id, user|
        described_class.create(client_id, user, { type: 'websocket' })
        described_class.queue(client_id)
      end
    end

    after do
      described_class.cleanup
    end

    def received
      sessions.keys.index_with { described_class.queue(it).pluck('event') }
    end

    describe '.deliver_many' do
      it 'sends to the authenticated sessions' do
        described_class.deliver_many([{ data: { event: 'one' }, recipient: 'authenticated' }])

        expect(received).to eq('a1' => ['one'], 'a2' => ['one'], 'b1' => ['one'], 'c1' => [])
      end

      it 'sends to the authenticated sessions without a recipient' do
        described_class.deliver_many([{ data: { event: 'one' }, recipient: nil }])

        expect(received).to eq('a1' => ['one'], 'a2' => ['one'], 'b1' => ['one'], 'c1' => [])
      end

      it 'sends to all sessions with the public recipient' do
        described_class.deliver_many([{ data: { event: 'one' }, recipient: 'public' }])

        expect(received).to eq('a1' => ['one'], 'a2' => ['one'], 'b1' => ['one'], 'c1' => ['one'])
      end

      it 'skips the sessions of the sender' do
        described_class.deliver_many([{ data: { event: 'one' }, recipient: 'public', sender_user_id: '11' }])

        expect(received).to eq('a1' => [], 'a2' => [], 'b1' => ['one'], 'c1' => ['one'])
      end

      it 'sends to the sessions of a user' do
        described_class.deliver_many([{ data: { event: 'one' }, user_id: '11' }])

        expect(received).to eq('a1' => ['one'], 'a2' => ['one'], 'b1' => [], 'c1' => [])
      end

      it 'skips a listed client id that is not valid' do
        allow(described_class).to receive(:sessions).and_return([*sessions.keys, '../c2'])
        allow(store).to receive(:get_many).and_call_original

        described_class.deliver_many([{ data: { event: 'one' }, recipient: 'public' }])

        expect(store).to have_received(:get_many).with(sessions.keys)
      end

      it 'skips a listed session without a value' do
        allow(described_class).to receive(:sessions).and_return([*sessions.keys, 'd1'])

        expect(described_class.deliver_many([{ data: { event: 'one' }, recipient: 'public' }])).to eq([sessions.keys])
      end

      it 'gives every client its messages in the given order' do
        described_class.deliver_many(
          [
            { data: { event: 'one' }, recipient: 'public' },
            { data: { event: 'two' }, user_id: 11 },
            { data: { event: 'three' }, recipient: 'authenticated', sender_user_id: 12 },
            { data: { event: 'four' }, user_id: 12 },
          ]
        )

        expect(received).to eq('a1' => %w[one two three], 'a2' => %w[one two three], 'b1' => %w[one four], 'c1' => ['one'])
      end

      it 'decides every message of a buffer on the sessions read at its start', :aggregate_failures do
        changed = false
        allow(store).to receive(:get_many).and_wrap_original do |original, client_ids|
          original.call(client_ids).tap do
            next if changed

            changed = true
            described_class.destroy('b1')
            described_class.create('d1', { 'id' => 13 }, { type: 'websocket' })
          end
        end
        buffer = [{ data: { event: 'one' }, recipient: 'authenticated' }, { data: { event: 'two' }, user_id: 12 }]

        expect(described_class.deliver_many(buffer)).to match([contain_exactly('a1', 'a2', 'b1'), ['b1']])
        expect(described_class.deliver_many(buffer)).to match([contain_exactly('a1', 'a2', 'd1'), []])
        expect(store).to have_received(:get_many).twice
      end

      it 'returns the recipients of every message' do
        expect(described_class.deliver_many([{ data: { event: 'one' }, user_id: 12 }, { data: { event: 'two' }, recipient: 'public', sender_user_id: 11 }]))
          .to match([contain_exactly('b1'), contain_exactly('b1', 'c1')])
      end

      it 'does nothing without messages', :aggregate_failures do
        allow(store).to receive(:get_many).and_call_original

        expect(described_class.deliver_many([])).to eq([])
        expect(store).not_to have_received(:get_many)
      end

      it 'sends nothing without sessions' do
        described_class.cleanup

        expect(described_class.deliver_many([{ data: { event: 'one' }, recipient: 'public' }])).to eq([[]])
      end
    end

    describe '.broadcast' do
      it 'returns the client ids of the recipients' do
        expect(described_class.broadcast({ event: 'one' }, 'authenticated', 11)).to contain_exactly('b1')
      end
    end

    describe '.send_to' do
      it 'returns true' do
        expect(described_class.send_to(11, { event: 'one' })).to be(true)
      end
    end
  end

  describe '.queue' do
    it 'returns empty array for invalid client_id' do
      expect(described_class.queue('../malicious')).to eq([])
    end
  end

  describe 'creating and destroying a session for a real user' do
    subject(:client_id) { '123456789' }

    let(:agent) do
      User.create_or_update(
        login:         'session-agent-1',
        firstname:     'Session',
        lastname:      'Agent 1',
        email:         'session-agent1@example.com',
        password:      'agentpw',
        active:        true,
        roles:         Role.where(name: %w[Agent]),
        groups:        Group.all,
        updated_by_id: 1,
        created_by_id: 1,
      )
    end

    after do
      described_class.destroy(client_id)
    end

    it 'creates a session, attaches the user on login, and removes it again on destroy', :aggregate_failures do
      described_class.create(client_id, {}, { type: 'websocket' })

      expect(described_class.session_exists?(client_id)).to be(true)

      data = described_class.get(client_id)
      expect(data[:meta]).to be_truthy
      expect(data[:user]).to be_truthy
      expect(data[:user]['id']).to be_nil

      # recreate session once the user has logged in
      described_class.create(client_id, agent.attributes, { type: 'websocket' })

      expect(described_class.session_exists?(client_id)).to be(true)

      data = described_class.get(client_id)
      expect(data[:meta]).to be_truthy
      expect(data[:user]).to be_truthy
      expect(data[:user]['id']).to eq(agent.id)

      described_class.destroy(client_id)

      expect(described_class.session_exists?(client_id)).to be(false)
    end
  end
end
