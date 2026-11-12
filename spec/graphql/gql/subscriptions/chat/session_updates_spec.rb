# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which legacy events trigger a push is covered by spec/models/chat/session_spec.rb — this covers the
#   subscription surface only: the payload and the authorization, driven by the legacy handlers.
RSpec.describe Gql::Subscriptions::Chat::SessionUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription chatSessionUpdates($sessionId: ID!) {
        chatSessionUpdates(sessionId: $sessionId) {
          message {
            id
            content
            createdBy {
              id
            }
          }
          typing
          notice
          leftBy
          closedBy
        }
      }
    QUERY
  end
  let(:variables)    { { sessionId: gql.id(chat_session) } }
  let(:mock_channel) { build_mock_channel }

  let(:chat_enabled)       { true }
  let(:topic)              { create(:chat, name: 'Support') }
  let(:preferences)        { { chat: { active: { topic.id.to_s => 'on' } } } }
  let(:agent)              { create(:agent, preferences:) }
  let(:customer_client_id) { SecureRandom.uuid }
  let(:chat_session_owner) { agent }
  let(:chat_session_state) { 'running' }
  let(:chat_session) do
    create(:'chat/session', chat: topic, state: chat_session_state, user: chat_session_owner, preferences: { participants: [customer_client_id] })
  end

  def pushed
    mock_channel.mock_broadcasted_messages.map { |message| message.dig(:result, 'data', 'chatSessionUpdates') }
  end

  def handle_event(event_class, data = {}, client_id: customer_client_id, session: nil, chat_session: self.chat_session)
    # The legacy handlers run in the websocket server, which has no current user.
    UserInfo.current_user_id = nil

    event_class.new(
      payload:   { 'data' => data.merge('session_id' => chat_session.session_id) },
      client_id: client_id,
      session:   session,
    ).run
  end

  before do
    Setting.set('chat', chat_enabled)
    gql.execute(subscription, variables:, context: { channel: mock_channel })
  end

  context 'with the agent of the session', authenticated_as: :agent do
    it 'subscribes without an initial payload' do
      expect(gql.result.data).to eq({ 'message' => nil, 'typing' => nil, 'notice' => nil, 'leftBy' => nil, 'closedBy' => nil })
    end

    it 'receives a message of the customer' do
      handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Hello' })

      expect(pushed).to eq([
                             { 'message' => { 'id' => gql.id(Chat::Message.last), 'content' => 'Hello', 'createdBy' => nil }, 'typing' => nil, 'notice' => nil, 'leftBy' => nil, 'closedBy' => nil },
                           ])
    end

    it 'receives a message the agent wrote in another window' do
      handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Hi there' }, client_id: SecureRandom.uuid, session: { 'id' => agent.id })

      expect(pushed.first['message']).to include('content' => 'Hi there', 'createdBy' => { 'id' => gql.id(agent) })
    end

    it 'receives that the customer is typing' do
      handle_event(Sessions::Event::ChatSessionTyping)

      expect(pushed).to eq([{ 'message' => nil, 'typing' => true, 'notice' => nil, 'leftBy' => nil, 'closedBy' => nil }])
    end

    it 'does not receive that the agent is typing in another window' do
      handle_event(Sessions::Event::ChatSessionTyping, {}, client_id: SecureRandom.uuid, session: { 'id' => agent.id })

      expect(pushed).to be_empty
    end

    it 'receives a notice about the customer' do
      handle_event(Sessions::Event::ChatSessionNotice, { 'message' => 'The customer moved to https://example.com/pricing' })

      expect(pushed.first).to include('notice' => 'The customer moved to https://example.com/pricing')
    end

    it 'receives that the customer left' do
      ChatLeaveJob.perform_now(chat_session.id, customer_client_id, nil)

      expect(pushed.first).to include('leftBy' => 'Anonymous')
    end

    it 'receives that the customer closed the conversation' do
      handle_event(Sessions::Event::ChatSessionClose)

      expect(pushed.first).to include('closedBy' => 'Anonymous')
    end

    it 'receives that the cleanup closed the conversation' do
      chat_session.update_columns(updated_at: 10.minutes.ago)

      Chat.cleanup_close

      expect(pushed.first).to include('closedBy' => 'System')
    end

    it 'receives nothing that is meant for the customer only' do
      chat_session.send_to_recipients({ event: 'chat_session_queue', data: { state: 'queue', position: 1, session_id: chat_session.session_id } })

      expect(pushed).to be_empty
    end

    it 'receives nothing of another session of the agent' do
      other_session = create(:'chat/session', chat: topic, state: 'running', user: agent, preferences: { participants: [customer_client_id] })

      handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Hello' }, chat_session: other_session)

      expect(pushed).to be_empty
    end

    # A colleague reading along in a window of their own gets what the customer says and does.
    context 'when another agent runs the session' do
      let(:chat_session_owner) { create(:agent, preferences:) }

      it 'receives a message of the customer' do
        handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Hello' })

        expect(pushed.first).to include('message' => include('content' => 'Hello'))
      end

      it 'receives that the conversation was closed' do
        handle_event(Sessions::Event::ChatSessionClose)

        expect(pushed.first).to include('closedBy' => 'Anonymous')
      end

      # Back in a queue the session pushes nothing; once a third agent takes it, the reader follows on.
      context 'when the session is transferred and a third agent takes it' do
        let(:other_topic) { create(:chat, name: 'Sales') }

        before do
          UserInfo.current_user_id = nil

          Sessions::Event::ChatTransfer.new(
            payload:   { 'data' => { 'session_id' => chat_session.session_id }, 'session_id' => chat_session.id, 'chat_id' => other_topic.id },
            client_id: SecureRandom.uuid,
            session:   { 'id' => chat_session_owner.id },
          ).run
        end

        it 'receives what the customer says to the third agent, and nothing while the session waited', :aggregate_failures do
          handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Anybody there?' })

          expect(pushed).to be_empty

          Chat::Session.claim_next([other_topic.id], create(:agent))
          handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Hello again' })

          expect(pushed.map { |update| update.dig('message', 'content') }).to eq(['Hello again'])
        end
      end
    end

    context 'when the session is still waiting' do
      let(:chat_session_owner) { nil }
      let(:chat_session_state) { 'waiting' }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'when the id is no chat session' do
      let(:variables) { { sessionId: gql.id(agent) } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    # A transfer puts the session back into a queue without taking it from its agent.
    context 'when the session gets transferred' do
      let(:other_topic) { create(:chat, name: 'Sales') }

      before do
        UserInfo.current_user_id = nil

        Sessions::Event::ChatTransfer.new(
          payload:   { 'data' => { 'session_id' => chat_session.session_id }, 'session_id' => chat_session.id, 'chat_id' => other_topic.id },
          client_id: SecureRandom.uuid,
          session:   { 'id' => agent.id },
        ).run
      end

      it 'receives nothing any more' do
        handle_event(Sessions::Event::ChatSessionMessage, { 'content' => 'Anybody there?' })

        expect(pushed).to be_empty
      end

      it 'is forbidden to subscribe to again' do
        gql.execute(subscription, variables:, context: { channel: build_mock_channel })

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a user without the chat.agent permission', authenticated_as: :user do
    let(:user)               { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }
    let(:chat_session_owner) { user }

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
