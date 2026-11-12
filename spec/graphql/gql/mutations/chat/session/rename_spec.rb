# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Who may name which session is covered by spec/services/service/chat/session/rename_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Session::Rename, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatSessionRename($sessionId: ID!, $name: String!) {
        chatSessionRename(sessionId: $sessionId, name: $name) {
          session {
            id
            name
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
  let(:topic)         { create(:chat, name: 'Support') }
  let(:agent)         { create(:agent) }
  let(:session_owner) { agent }
  let(:session)       { create(:'chat/session', chat: topic, state: 'running', user: session_owner) }
  let(:variables)     { { sessionId: gql.id(session), name: 'Pricing question' } }

  before do
    Setting.set('chat', chat_enabled)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the named session' do
      expect(gql.result.data['session']).to eq({ 'id' => gql.id(session), 'name' => 'Pricing question' })
    end

    context 'with the session of another agent' do
      let(:session_owner) { create(:agent) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'without a name' do
      let(:variables) { { sessionId: gql.id(session) } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to eq('Variable $name of type String! was provided invalid value')
      end
    end

    context 'with an id that is no chat session' do
      let(:variables) { { sessionId: gql.id(agent), name: 'Pricing question' } }

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
