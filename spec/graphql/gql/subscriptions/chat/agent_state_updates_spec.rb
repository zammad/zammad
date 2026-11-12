# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What the state holds is covered by spec/services/service/chat/agent_state_spec.rb, and which legacy
#   event triggers a push by spec/models/chat_spec.rb — this covers the subscription surface only:
#   the payload, the per-user scope and authorization, driven by the legacy handlers and the services.
RSpec.describe Gql::Subscriptions::Chat::AgentStateUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription chatAgentStateUpdates {
        chatAgentStateUpdates {
          agentState {
            active
            waitingQueues {
              topic {
                id
              }
              sessions {
                id
              }
            }
            runningSessions {
              id
            }
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }

  let(:chat_enabled)       { true }
  let(:topic)              { create(:chat, name: 'Support') }
  let(:preferences)        { { chat: { active: { topic.id.to_s => 'on' } } } }
  let(:agent)              { create(:agent, preferences:) }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:waiting_session) do
    create(:'chat/session', chat: topic, state: 'waiting', preferences: { participants: [customer_client_id] })
  end

  def pushed_states
    mock_channel.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'chatAgentStateUpdates', 'agentState') }
  end

  def customer_asks_for_chat
    Sessions::Event::ChatSessionInit.new(
      payload:   { 'data' => { 'chat_id' => topic.id, 'url' => 'https://example.com/pricing' } },
      client_id: customer_client_id,
    ).run
  end

  before do
    Setting.set('chat', chat_enabled)
    create(:'chat/agent', concurrent: 2, updated_by: agent, created_by: agent)
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'subscribes without an initial payload' do
      expect(gql.result.data).to eq({ 'agentState' => nil })
    end

    it 'receives the state recomputed for them when a customer asks for a chat' do
      customer_asks_for_chat

      expect(pushed_states).to eq([
                                    {
                                      'active'          => true,
                                      'waitingQueues'   => [{ 'topic' => { 'id' => gql.id(topic) }, 'sessions' => [{ 'id' => gql.id(Chat::Session.last) }] }],
                                      'runningSessions' => [],
                                    },
                                  ])
    end

    it 'receives the state when a conversation was closed' do
      session = create(:'chat/session', chat: topic, state: 'running', user: agent, preferences: { participants: [customer_client_id] })

      Sessions::Event::ChatSessionClose.new(
        payload:   { 'data' => { 'session_id' => session.session_id } },
        client_id: SecureRandom.uuid,
        session:   { 'id' => agent.id },
      ).run

      expect(pushed_states).to eq([{ 'active' => true, 'waitingQueues' => [{ 'topic' => { 'id' => gql.id(topic) }, 'sessions' => [] }], 'runningSessions' => [] }])
    end

    it 'receives the state when a customer left for good' do
      session = create(:'chat/session', chat: topic, state: 'running', user: agent, preferences: { participants: [customer_client_id] })

      ChatLeaveJob.perform_now(session.id, customer_client_id, nil)

      expect(pushed_states.size).to eq(1)
    end

    it 'receives the state when the cleanup closes a waiting session' do
      waiting_session.update_columns(updated_at: 10.minutes.ago)

      Chat.cleanup_close

      expect(pushed_states).to eq([{ 'active' => true, 'waitingQueues' => [{ 'topic' => { 'id' => gql.id(topic) }, 'sessions' => [] }], 'runningSessions' => [] }])
    end

    it 'receives the state of their own change of availability' do
      Chat.broadcast_agent_state_update([topic.id], agent.id)

      expect(pushed_states.size).to eq(1)
    end

    # This is any other window of theirs: the one that saved reads the state itself.
    it 'receives the state when they drop their last topic, which switches them unavailable' do
      Service::Chat::Preferences::Update.with_current_user(agent).execute(topics: [{ topic:, active: false }])

      expect(pushed_states).to eq([{ 'active' => false, 'waitingQueues' => [], 'runningSessions' => [] }])
    end

    # The old UI stores the availability by opening the chat page, the new one does not.
    context 'when the agent never stored an availability' do
      before do
        Chat::Agent.destroy_all
      end

      it 'receives the state when a customer asks for a chat' do
        customer_asks_for_chat

        expect(pushed_states.size).to eq(1)
      end
    end

    context 'when the agent handles another topic only' do
      let(:preferences) { { chat: { active: { create(:chat, name: 'Sales').id.to_s => 'on' } } } }

      it 'receives nothing for a customer in the queue of this topic' do
        customer_asks_for_chat

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end

  context 'with a colleague of the topic', authenticated_as: :colleague do
    let(:colleague) { create(:agent, preferences:) }

    it 'receives the state when the agent drops their last topic, which takes them out of it' do
      Service::Chat::Preferences::Update.with_current_user(agent).execute(topics: [{ topic:, active: false }])

      expect(pushed_states.size).to eq(1)
    end
  end

  context 'with a user without the chat.agent permission', authenticated_as: :user do
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  context 'when the chat feature is switched off', authenticated_as: :agent do
    let(:chat_enabled) { false }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
