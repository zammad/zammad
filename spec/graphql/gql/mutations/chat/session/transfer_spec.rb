# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What a transfer changes and tells is covered by spec/services/service/chat/session/transfer_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Session::Transfer, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatSessionTransfer($sessionId: ID!, $topicId: ID!) {
        chatSessionTransfer(sessionId: $sessionId, topicId: $topicId) {
          session {
            id
            state
            topic {
              id
            }
          }
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:chat_enabled)  { true }
  let(:support)       { create(:chat, name: 'Support') }
  let(:sales)         { create(:chat, name: 'Sales') }
  let(:agent)         { create(:agent, preferences: { chat: { active: { support.id.to_s => 'on' } } }) }
  let(:session_owner) { agent }
  let(:session)       { create(:'chat/session', chat: support, state: 'running', user: session_owner, preferences: { participants: [SecureRandom.uuid] }) }
  let(:variables)     { { sessionId: gql.id(session), topicId: gql.id(sales) } }

  before do
    Setting.set('chat', chat_enabled)
    allow(Chat).to receive(:broadcast_agent_state_update)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the session in the queue of the other topic', :aggregate_failures do
      expect(gql.result.data['session']).to eq({ 'id' => gql.id(session), 'state' => 'waiting', 'topic' => { 'id' => gql.id(sales) } })
      expect(gql.result.data['errors']).to be_nil
    end

    context 'with the session of another agent' do
      let(:session_owner) { create(:agent) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with an id that is no chat session' do
      let(:variables) { { sessionId: gql.id(agent), topicId: gql.id(sales) } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'with an id that is no topic' do
      let(:variables) { { sessionId: gql.id(session), topicId: gql.id(agent) } }

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
