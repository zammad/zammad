# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Chat::Session, type: :graphql do
  let(:query) do
    <<~GQL
      query chatSession($sessionId: ID!) {
        chatSession(sessionId: $sessionId) {
          id
          state
          url
          tags
          messages {
            id
            content
            createdBy {
              id
            }
          }
        }
      }
    GQL
  end

  let(:chat_enabled)     { true }
  let(:topic)            { create(:chat, name: 'Support') }
  let(:agent)            { create(:agent) }
  let(:session_owner)    { agent }
  let(:session_state)    { 'running' }
  let(:session) do
    create(:'chat/session', chat: topic, state: session_state, user: session_owner, preferences: { url: 'https://example.com/pricing' })
  end
  let(:customer_message) { create(:'chat/message', chat_session: session, content: 'Hello', created_by_id: nil) }
  let(:agent_message)    { create(:'chat/message', chat_session: session, content: 'Hi there', created_by: agent) }
  let(:variables)        { { sessionId: gql.id(session) } }

  before do
    Setting.set('chat', chat_enabled)
    customer_message
    agent_message
    session.tag_add('pricing', 1)
    gql.execute(query, variables:)
  end

  context 'with the agent of the session', authenticated_as: :agent do
    it 'returns the session with its conversation, oldest first', :aggregate_failures do
      expect(gql.result.data).to include('id' => gql.id(session), 'state' => 'running', 'url' => 'https://example.com/pricing', 'tags' => ['pricing'])
      expect(gql.result.data['messages']).to eq([
                                                  { 'id' => gql.id(customer_message), 'content' => 'Hello', 'createdBy' => nil },
                                                  { 'id' => gql.id(agent_message), 'content' => 'Hi there', 'createdBy' => { 'id' => gql.id(agent) } },
                                                ])
    end

    context 'with a closed session' do
      let(:session_state) { 'closed' }

      it 'still returns it' do
        expect(gql.result.data['state']).to eq('closed')
      end
    end

    # Found through search, a colleague's session opens for reading, running or not.
    context 'with the session of another agent' do
      let(:session_owner) { create(:agent) }

      it 'returns it with its conversation' do
        expect(gql.result.data).to include('state' => 'running', 'messages' => [include('content' => 'Hello'), include('content' => 'Hi there')])
      end
    end

    context 'with a session nobody runs' do
      let(:session_owner) { nil }
      let(:session_state) { 'waiting' }

      it 'returns it' do
        expect(gql.result.data).to include('state' => 'waiting')
      end
    end

    context 'with an id that is no chat session' do
      let(:variables) { { sessionId: gql.id(agent) } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the chat feature is switched off' do
      let(:chat_enabled) { false }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end

  context 'with a user without the chat.agent permission', authenticated_as: :user do
    let(:user)          { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }
    let(:session_owner) { user }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
