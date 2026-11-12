# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# What is stored and sent is covered by spec/services/service/chat/session/message_add_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Session::MessageAdd, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatSessionMessageAdd($sessionId: ID!, $content: String!) {
        chatSessionMessageAdd(sessionId: $sessionId, content: $content) {
          message {
            id
            content
            createdBy {
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
  let(:topic)         { create(:chat, name: 'Support') }
  let(:agent)         { create(:agent) }
  let(:session_owner) { agent }
  let(:session)       { create(:'chat/session', chat: topic, state: 'running', user: session_owner, preferences: { participants: [SecureRandom.uuid] }) }
  let(:content)       { 'Hello, how can I help you?' }
  let(:variables)     { { sessionId: gql.id(session), content: } }

  before do
    Setting.set('chat', chat_enabled)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the written message with its author', :aggregate_failures do
      expect(gql.result.data['message']).to eq({ 'id' => gql.id(Chat::Message.last), 'content' => 'Hello, how can I help you?', 'createdBy' => { 'id' => gql.id(agent) } })
      expect(gql.result.data['errors']).to be_nil
    end

    context 'without content' do
      let(:content) { '' }

      it 'returns the user error', :aggregate_failures do
        expect(gql.result.data['message']).to be_nil
        expect(gql.result.data['errors']).to eq([{ 'message' => 'The message must not be empty.', 'field' => nil }])
      end
    end

    context 'with the session of another agent' do
      let(:session_owner) { create(:agent) }

      it 'is forbidden' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    context 'with an id that is no chat session' do
      let(:variables) { { sessionId: gql.id(agent), content: } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'without the content' do
      let(:variables) { { sessionId: gql.id(session) } }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('$content')
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
