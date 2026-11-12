# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Which session the agent gets and what the customer is told is covered by
#   spec/services/service/chat/session/accept_spec.rb — this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Session::Accept, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatSessionAccept($topicId: ID) {
        chatSessionAccept(topicId: $topicId) {
          session {
            id
            state
            user {
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

  let(:chat_enabled) { true }
  let(:topic)        { create(:chat, name: 'Support') }
  let(:variables)    { {} }
  let(:agent)        { create(:agent, preferences: { chat: { active: { topic.id.to_s => 'on' } } }) }
  let(:waiting)      { create(:'chat/session', chat: topic, state: 'waiting', preferences: { participants: [SecureRandom.uuid] }) }

  before do
    Setting.set('chat', chat_enabled)
    waiting
    allow(Chat).to receive(:broadcast_agent_state_update)
    allow(Chat).to receive(:broadcast_customer_state_update)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the accepted session with the agent', :aggregate_failures do
      expect(gql.result.data['session']).to eq({ 'id' => gql.id(waiting), 'state' => 'running', 'user' => { 'id' => gql.id(agent) } })
      expect(gql.result.data['errors']).to be_nil
    end

    context 'with a topic' do
      let(:other_topic) { create(:chat, name: 'Sales') }
      let(:sales)       { create(:'chat/session', chat: other_topic, state: 'waiting', preferences: { participants: [SecureRandom.uuid] }) }
      let(:variables)   { { topicId: gql.id(other_topic) } }
      # Created before the mutation runs, next to the session in the topic of the agent.
      let(:waiting)     { super() && sales }

      it 'returns the session of that topic' do
        expect(gql.result.data['session']['id']).to eq(gql.id(sales))
      end
    end

    context 'with an id that is no topic' do
      let(:variables) { { topicId: gql.id(agent) } }

      it 'is not found' do
        expect(gql.result.error_type).to eq(ActiveRecord::RecordNotFound)
      end
    end

    context 'with nobody waiting' do
      let(:waiting) { nil }

      it 'returns the user error of the old interface', :aggregate_failures do
        expect(gql.result.data['session']).to be_nil
        expect(gql.result.data['errors']).to eq([{ 'message' => 'No session available.', 'field' => nil }])
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
    let(:user) { create(:user, roles: [create(:role, permission_names: 'ticket.agent')]) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
