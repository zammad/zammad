# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_xss_sanitized_note_examples'

RSpec.describe Chat, type: :model do
  it_behaves_like 'HasXssSanitizedNote', model_factory: :chat

  describe 'website allowing' do
    let(:chat) { create(:chat, allowed_websites: 'zammad.org') }

    it 'detects allowed website' do
      result = chat.website_allowed?('https://www.zammad.org')
      expect(result).to be true
    end

    it 'detects non-allowed website' do
      result = chat.website_allowed?('https://www.zammad.com')
      expect(result).to be false
    end

    it 'detects missing website as non-allowed', :aggregate_failures do
      expect(chat.website_allowed?(nil)).to be false
      expect(chat.website_allowed?('')).to be false
    end

    it 'allows missing website without allowed websites' do
      chat.update!(allowed_websites: nil)
      expect(chat.website_allowed?(nil)).to be true
    end
  end

  describe '#destroy' do
    let(:chat) { create(:chat) }
    let(:session) { create(:'chat/session', chat: chat) }

    before do
      session
    end

    it 'does delete chats properly if they have sessions' do
      expect { chat.destroy! }.not_to raise_error
    end
  end

  describe 'customer and agent state' do
    let(:chat)   { create(:chat) }
    let(:agent1) { create(:agent, firstname: 'Notification', lastname: 'Agent1') }
    let(:agent2) { create(:agent, firstname: 'Notification', lastname: 'Agent2') }

    def activate_chat_agent(user, concurrent)
      create(:'chat/agent', concurrent: concurrent, updated_by: user, created_by: user)
    end

    def expect_agent_state(user, expected_state)
      expect(described_class.agent_state_with_sessions(user.id)).to include(expected_state)
    end

    before do
      Setting.set('chat', true)

      [agent1, agent2].each do |agent|
        agent.preferences[:chat] = { active: { chat.id => 'on' } }
        agent.save!
      end
    end

    context 'when the chat feature is disabled' do
      before do
        Setting.set('chat', false)
      end

      it 'reports chat_disabled state to the customer' do
        expect(chat.customer_state[:state]).to eq('chat_disabled')
      end

      it 'reports chat_disabled state to the agent' do
        expect(described_class.agent_state(agent1.id)[:state]).to eq('chat_disabled')
      end
    end

    context 'when no chat agent is active' do
      it 'reports offline state to the customer' do
        expect(chat.customer_state[:state]).to eq('offline')
      end

      it 'reports no seats and no sessions to the agent' do
        expect_agent_state(agent1,
                           waiting_chat_count: 0,
                           running_chat_count: 0,
                           active_sessions:    [],
                           seads_available:    0,
                           seads_total:        0,
                           active:             false)
      end
    end

    context 'with one active chat agent' do
      before do
        activate_chat_agent(agent1, 4)
      end

      it 'reports online state to the customer' do
        expect(chat.customer_state[:state]).to eq('online')
      end

      it 'reports available seats to the agent' do
        expect_agent_state(agent1,
                           waiting_chat_count: 0,
                           running_chat_count: 0,
                           active_sessions:    [],
                           seads_available:    4,
                           seads_total:        4,
                           active:             true)
      end

      context 'with a waiting chat session' do
        let(:chat_session) { create(:'chat/session', chat: chat, user: agent1) }

        before do
          chat_session
        end

        it 'generates a session id' do
          expect(chat_session.session_id).to be_present
        end

        it 'reports online state to the customer' do
          expect(chat.customer_state[:state]).to eq('online')
        end

        it 'reports the waiting session to the agent' do
          expect_agent_state(agent1,
                             waiting_chat_count: 1,
                             running_chat_count: 0,
                             active_sessions:    [],
                             seads_available:    3,
                             seads_total:        4,
                             active:             true)
        end
      end
    end

    context 'with two active chat agents' do
      let(:chat_agent2) { activate_chat_agent(agent2, 2) }

      before do
        activate_chat_agent(agent1, 4)
        chat_agent2
      end

      context 'with a waiting chat session' do
        before do
          create(:'chat/session', chat: chat, user: agent1)
        end

        it 'reports online state to the customer' do
          expect(chat.customer_state[:state]).to eq('online')
        end

        it 'reports the waiting session and combined seats to both agents', :aggregate_failures do
          [agent1, agent2].each do |agent|
            expect_agent_state(agent,
                               waiting_chat_count: 1,
                               running_chat_count: 0,
                               active_sessions:    [],
                               seads_available:    5,
                               seads_total:        6,
                               active:             true)
          end
        end
      end

      context 'with two waiting chat sessions' do
        before do
          create_list(:'chat/session', 2, chat: chat)
        end

        it 'reports online state to the customer' do
          expect(chat.customer_state[:state]).to eq('online')
        end

        it 'reports both waiting sessions to both agents', :aggregate_failures do
          [agent1, agent2].each do |agent|
            expect_agent_state(agent,
                               waiting_chat_count: 2,
                               running_chat_count: 0,
                               active_sessions:    [],
                               seads_available:    4,
                               seads_total:        6,
                               active:             true)
          end
        end
      end

      context 'with six waiting chat sessions' do
        let(:chat_sessions) { create_list(:'chat/session', 6, chat: chat) }

        before do
          chat_sessions
        end

        it 'reports no_seats_available state to the customer' do
          expect(chat.customer_state[:state]).to eq('no_seats_available')
        end

        it 'reports all waiting sessions and no available seats to both agents', :aggregate_failures do
          [agent1, agent2].each do |agent|
            expect_agent_state(agent,
                               waiting_chat_count: 6,
                               running_chat_count: 0,
                               active_sessions:    [],
                               seads_available:    0,
                               seads_total:        6,
                               active:             true)
          end
        end

        context 'when one chat session is running' do
          let(:running_session)  { chat_sessions.last }
          let(:message_contents) { ['message 1', 'message 2', 'message 3', 'message 4'] }

          before do
            running_session.update!(user: agent1, state: 'running')

            create(:'chat/message', chat_session: running_session, content: 'message 1', created_by_id: agent1.id)
            travel 1.second
            create(:'chat/message', chat_session: running_session, content: 'message 2', created_by_id: agent1.id)
            travel 1.second
            create(:'chat/message', chat_session: running_session, content: 'message 3', created_by_id: agent1.id)
            travel 1.second
            create(:'chat/message', chat_session: running_session, content: 'message 4', created_by_id: nil)
          end

          it 'reports no_seats_available state and queue position to the customer' do
            expect(chat.customer_state).to include(state: 'no_seats_available', queue: 5)
          end

          it 'reports reconnect state with all messages to the customer of the running session', :aggregate_failures do
            customer_state = chat.customer_state(running_session.session_id)

            expect(customer_state).to include(state: 'reconnect')
            expect(customer_state[:session].pluck('content')).to eq(message_contents)
            expect(customer_state[:agent]).to include(name: 'Notification Agent1', avatar: nil)
          end

          it 'reports the running session with all messages to the assigned agent', :aggregate_failures do
            agent_state = described_class.agent_state_with_sessions(agent1.id)

            expect(agent_state).to include(
              waiting_chat_count: 5,
              running_chat_count: 1,
              seads_available:    0,
              seads_total:        6,
              active:             true,
            )
            expect(agent_state[:active_sessions].first).to include('chat_id' => chat.id, 'user_id' => agent1.id)
            expect(agent_state[:active_sessions].first['messages'].pluck('content')).to eq(message_contents)
          end

          it 'reports the running session without active sessions to the other agent' do
            expect_agent_state(agent2,
                               waiting_chat_count: 5,
                               running_chat_count: 1,
                               active_sessions:    [],
                               seads_available:    0,
                               seads_total:        6,
                               active:             true)
          end

          context 'when the second chat agent becomes inactive' do
            before do
              chat_agent2.update!(active: false)
            end

            it 'reports no_seats_available state and queue position to the customer' do
              expect(chat.customer_state).to include(state: 'no_seats_available', queue: 5)
            end

            it 'reports overbooked seats to the assigned agent', :aggregate_failures do
              agent_state = described_class.agent_state_with_sessions(agent1.id)

              expect(agent_state).to include(
                waiting_chat_count: 5,
                running_chat_count: 1,
                seads_available:    -2,
                seads_total:        4,
                active:             true,
              )
              expect(agent_state[:active_sessions].first).to include('chat_id' => chat.id, 'user_id' => agent1.id)
            end

            it 'reports inactive state to the second agent' do
              expect_agent_state(agent2,
                                 waiting_chat_count: 5,
                                 running_chat_count: 1,
                                 active_sessions:    [],
                                 seads_available:    -2,
                                 seads_total:        4,
                                 active:             false)
            end
          end

          context 'when the second chat agent becomes inactive and the running session is closed' do
            before do
              chat_agent2.update!(active: false)
              running_session.update!(state: 'closed')
            end

            it 'reports no_seats_available state and queue position to the customer' do
              expect(chat.customer_state).to include(state: 'no_seats_available', queue: 5)
            end

            it 'reports no running sessions to the first agent' do
              expect_agent_state(agent1,
                                 waiting_chat_count: 5,
                                 running_chat_count: 0,
                                 active_sessions:    [],
                                 seads_available:    -1,
                                 seads_total:        4,
                                 active:             true)
            end

            it 'reports no running sessions to the second agent' do
              expect_agent_state(agent2,
                                 waiting_chat_count: 5,
                                 running_chat_count: 0,
                                 active_sessions:    [],
                                 seads_available:    -1,
                                 seads_total:        4,
                                 active:             false)
            end
          end

          context 'when the second chat agent becomes inactive, the running session is closed and two waiting sessions are removed' do
            before do
              chat_agent2.update!(active: false)
              running_session.update!(state: 'closed')
              chat_sessions[3].destroy
              chat_sessions[4].destroy
            end

            it 'reports online state to the customer' do
              expect(chat.customer_state[:state]).to eq('online')
            end

            it 'reports available seats to the first agent' do
              expect_agent_state(agent1,
                                 waiting_chat_count: 3,
                                 running_chat_count: 0,
                                 active_sessions:    [],
                                 seads_available:    1,
                                 seads_total:        4,
                                 active:             true)
            end

            it 'reports available seats to the second agent' do
              expect_agent_state(agent2,
                                 waiting_chat_count: 3,
                                 running_chat_count: 0,
                                 active_sessions:    [],
                                 seads_available:    1,
                                 seads_total:        4,
                                 active:             false)
            end
          end
        end
      end
    end
  end

  describe '.agent_state_with_sessions with multiple chat topics' do
    let(:chat1)  { create(:chat, name: 'topic 1') }
    let(:chat2)  { create(:chat, name: 'topic 2') }
    let(:agent1) { create(:agent) }
    let(:agent2) { create(:agent) }

    def expect_agent_state(user, expected_state)
      expect(described_class.agent_state_with_sessions(user.id)).to include(expected_state)
    end

    before do
      Setting.set('chat', true)

      agent1.preferences[:chat] = { active: { chat1.id.to_s => 'on' } }
      agent1.save!

      agent2.preferences[:chat] = { active: { chat2.id.to_s => 'on' } }
      agent2.save!
    end

    context 'when no chat agent is active' do
      it 'reports offline state to customers of both chats', :aggregate_failures do
        expect(chat1.customer_state[:state]).to eq('offline')
        expect(chat2.customer_state[:state]).to eq('offline')
      end
    end

    context 'when the first chat agent is active' do
      before do
        create(:'chat/agent', concurrent: 4, updated_by: agent1, created_by: agent1)
      end

      it 'reports online state only to customers of the first chat', :aggregate_failures do
        expect(chat1.customer_state[:state]).to eq('online')
        expect(chat2.customer_state[:state]).to eq('offline')
      end

      it 'reports no seats and no sessions to the second agent' do
        expect_agent_state(agent2,
                           waiting_chat_count: 0,
                           running_chat_count: 0,
                           active_sessions:    [],
                           seads_available:    0,
                           seads_total:        0,
                           active:             false)
      end

      context 'when the second chat agent is active' do
        before do
          create(:'chat/agent', concurrent: 2, updated_by: agent2, created_by: agent2)
        end

        it 'reports online state to customers of both chats', :aggregate_failures do
          expect(chat1.customer_state[:state]).to eq('online')
          expect(chat2.customer_state[:state]).to eq('online')
        end

        context 'with a waiting session in the first chat' do
          before do
            create(:'chat/session', chat: chat1, user: agent1)
          end

          it 'reports the waiting session only to the first agent' do
            expect_agent_state(agent1,
                               waiting_chat_count: 1,
                               running_chat_count: 0,
                               active_sessions:    [],
                               seads_available:    3,
                               seads_total:        4,
                               active:             true)
          end

          it 'reports no waiting session to the second agent' do
            expect_agent_state(agent2,
                               waiting_chat_count: 0,
                               running_chat_count: 0,
                               active_sessions:    [],
                               seads_available:    2,
                               seads_total:        2,
                               active:             true)
          end
        end
      end
    end
  end

  describe '.agent_active_chat_ids' do
    let(:chat1)  { create(:chat, name: 'topic 1') }
    let(:chat2)  { create(:chat, name: 'topic 2') }
    let(:agent1) { create(:agent) }
    let(:agent2) { create(:agent) }

    context 'when agents have no chat preferences' do
      it 'returns no chat ids', :aggregate_failures do
        expect(described_class.agent_active_chat_ids(agent1)).to eq([])
        expect(described_class.agent_active_chat_ids(agent2)).to eq([])
      end
    end

    context 'when chats are activated in agent preferences' do
      before do
        agent1.preferences[:chat] = { active: { chat1.id.to_s => 'on' } }
        agent1.save!

        agent2.preferences[:chat] = { active: { chat2.id => 'on' } }
        agent2.save!
      end

      it 'returns activated chat ids for string and integer preference keys', :aggregate_failures do
        expect(described_class.agent_active_chat_ids(agent1)).to eq([chat1.id])
        expect(described_class.agent_active_chat_ids(agent2)).to eq([chat2.id])
      end
    end

    context 'when a chat is deactivated in agent preferences' do
      before do
        agent2.preferences[:chat] = { active: { chat2.id => 'off' } }
        agent2.save!
      end

      it 'returns no chat ids' do
        expect(described_class.agent_active_chat_ids(agent2)).to eq([])
      end
    end
  end

  describe '.agent_phrases' do
    subject(:phrases) { described_class.agent_phrases(chat_preferences, chat.id) }

    let(:chat)             { create(:chat) }
    let(:other_chat)       { create(:chat, name: 'other') }
    let(:chat_preferences) { { phrase: { chat.id.to_s => ' Hello, I am Erika;Good day ;; ' } } }

    it 'returns the greetings without the blank ones and the spaces around' do
      expect(phrases).to eq(['Hello, I am Erika', 'Good day'])
    end

    context 'with the chat id stored as a number' do
      let(:chat_preferences) { { phrase: { chat.id => 'Hello, I am Erika' } } }

      it 'returns the greetings' do
        expect(phrases).to eq(['Hello, I am Erika'])
      end
    end

    context 'with greetings of another chat only' do
      let(:chat_preferences) { { phrase: { other_chat.id.to_s => 'Hello, I am Erika' } } }

      it 'returns none' do
        expect(phrases).to eq([])
      end
    end

    context 'without chat preferences' do
      let(:chat_preferences) { nil }

      it 'returns none' do
        expect(phrases).to eq([])
      end
    end
  end

  describe '.broadcast_agent_state_update' do
    let(:support)           { create(:chat, name: 'Support') }
    let(:sales)             { create(:chat, name: 'Sales') }
    let!(:agent)            { create(:agent, preferences: { chat: { active: { support.id.to_s => 'on' } } }) }
    let!(:colleague)        { create(:agent, preferences: { chat: { active: { support.id.to_s => 'on' } } }) }
    let!(:sales_agent)      { create(:agent, preferences: { chat: { active: { sales.id.to_s => 'on' } } }) }
    let!(:customer)         { create(:customer, preferences: { chat: { active: { support.id.to_s => 'on' } } }) }
    let(:subscription_stub) { Gql::Subscriptions::Chat::AgentStateUpdates }

    before do
      allow(subscription_stub).to receive(:trigger_for)
      allow(Sessions).to receive(:send_to)
    end

    # The old UI stores an availability by opening the chat page, the new one does not.
    it 'triggers the subscription for each chat agent of the topics without a stored availability', :aggregate_failures do
      described_class.broadcast_agent_state_update([support.id])

      expect(subscription_stub).to have_received(:trigger_for).with(agent)
      expect(subscription_stub).to have_received(:trigger_for).with(colleague)
      expect(subscription_stub).not_to have_received(:trigger_for).with(sales_agent)
      expect(subscription_stub).not_to have_received(:trigger_for).with(customer)
    end

    # The agent who made the change gets the legacy state as the reply of their client, but their other
    #   windows of the new UI have no reply to wait for.
    it 'triggers the subscription for the agent who made the change as well', :aggregate_failures do
      described_class.broadcast_agent_state_update([support.id], agent.id)

      expect(subscription_stub).to have_received(:trigger_for).with(agent)
      expect(subscription_stub).to have_received(:trigger_for).with(colleague)
    end

    # The session of an agent can sit in a topic they switched off, which they still see in their windows.
    it 'triggers the subscription for the named agents whatever topics they handle', :aggregate_failures do
      described_class.broadcast_agent_state_update([support.id], agent_ids: [sales_agent.id])

      expect(subscription_stub).to have_received(:trigger_for).with(sales_agent).once
      expect(subscription_stub).to have_received(:trigger_for).with(agent)
    end

    it 'does not trigger the subscription for a named user without the chat permission' do
      described_class.broadcast_agent_state_update([support.id], agent_ids: [customer.id])

      expect(subscription_stub).not_to have_received(:trigger_for).with(customer)
    end

    context 'with stored availabilities' do
      before do
        [agent, colleague, sales_agent].each { |user| create(:'chat/agent', updated_by: user, created_by: user) }
      end

      it 'still leaves the legacy state to the reply for the agent who made the change', :aggregate_failures do
        described_class.broadcast_agent_state_update([support.id], agent.id)

        expect(Sessions).to have_received(:send_to).with(colleague.id, hash_including(event: 'chat_status_agent'))
        expect(Sessions).not_to have_received(:send_to).with(agent.id, anything)
      end
    end
  end

  describe '.cleanup_close' do
    let(:chat) { create(:chat, name: 'Support') }

    def waiting_session(updated_at:)
      create(:'chat/session', chat:, state: 'waiting', preferences: { participants: [SecureRandom.uuid] }).tap do |session|
        session.update_columns(updated_at:)
      end
    end

    before do
      allow(described_class).to receive(:broadcast_agent_state_update)
    end

    it 'closes the sessions nobody takes part in any more' do
      session = waiting_session(updated_at: 10.minutes.ago)

      described_class.cleanup_close

      expect(session.reload.state).to eq('closed')
    end

    it 'tells the agents of each affected topic once', :aggregate_failures do
      waiting_session(updated_at: 10.minutes.ago)
      waiting_session(updated_at: 10.minutes.ago)

      described_class.cleanup_close

      expect(described_class).to have_received(:broadcast_agent_state_update).with([chat.id], agent_ids: []).once
    end

    it 'keeps the agents out of it while nothing was closed', :aggregate_failures do
      session = waiting_session(updated_at: 1.minute.ago)

      described_class.cleanup_close

      expect(session.reload.state).to eq('waiting')
      expect(described_class).not_to have_received(:broadcast_agent_state_update)
    end

    # An agent of the new UI is no client of the legacy websocket, their beat keeps the session.
    context 'with a running session of an agent without a client' do
      let(:agent)           { create(:agent) }
      let(:customer_client) { SecureRandom.uuid }
      let!(:session) do
        create(:'chat/session', chat:, state: 'running', user: agent, preferences: { participants: [customer_client] }).tap do |record|
          record.update_columns(updated_at: 10.minutes.ago)
        end
      end

      def beat(time)
        create(:'chat/agent', updated_by: agent).update_columns(updated_at: time)
      end

      before { Sessions.create(customer_client, {}, {}) }

      after { Sessions.destroy(customer_client) }

      it 'keeps it open while the agent beats', :aggregate_failures do
        beat(1.minute.ago)

        described_class.cleanup_close

        expect(session.reload.state).to eq('running')
        expect(described_class).not_to have_received(:broadcast_agent_state_update)
      end

      it 'closes it once the beat of the agent is stale and tells the agent', :aggregate_failures do
        beat(3.minutes.ago)

        described_class.cleanup_close

        expect(session.reload.state).to eq('closed')
        expect(described_class).to have_received(:broadcast_agent_state_update).with([chat.id], agent_ids: [agent.id])
      end
    end
  end

  describe '#blocked_ip?' do
    let(:chat) { create(:chat, name: 'ip test', block_ip: '127.0.0.1;127.0.0.2;127.1.0.*') }

    it 'does not block unlisted IP addresses' do
      expect(chat.blocked_ip?('128.0.0.1')).to be(false)
    end

    it 'does not block IP addresses not matching a wildcard' do
      expect(chat.blocked_ip?('127.0.0.30')).to be(false)
    end

    it 'blocks listed IP addresses', :aggregate_failures do
      expect(chat.blocked_ip?('127.0.0.1')).to be(true)
      expect(chat.blocked_ip?('127.0.0.2')).to be(true)
    end

    it 'blocks IP addresses matching a wildcard', :aggregate_failures do
      expect(chat.blocked_ip?('127.1.0.1')).to be(true)
      expect(chat.blocked_ip?('127.1.0.100')).to be(true)
    end
  end

  describe '#blocked_country?' do
    let(:chat) { create(:chat, name: 'country test', block_country: 'AU;CH;DE') }

    before do
      allow(Service::GeoIp).to receive(:location).with('127.0.0.1').and_return({})
      allow(Service::GeoIp).to receive(:location).with('116.203.82.166').and_return({ 'country_code' => 'DE' })
    end

    it 'does not block IP addresses without a country' do
      expect(chat.blocked_country?('127.0.0.1')).to be(false)
    end

    it 'blocks IP addresses from a blocked country' do
      expect(chat.blocked_country?('116.203.82.166')).to be(true)
    end
  end
end
