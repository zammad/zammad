# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behavior is covered by spec/services/service/chat/agent/availability_update_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Agent::AvailabilityUpdate, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatAgentAvailabilityUpdate($active: Boolean!) {
        chatAgentAvailabilityUpdate(active: $active) {
          active
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:chat_enabled) { true }
  let(:variables)    { { active: true } }
  let(:agent)        { create(:agent) }

  before do
    Setting.set('chat', chat_enabled)
    allow(Chat).to receive(:broadcast_agent_state_update)
    gql.execute(mutation, variables:)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'returns the availability as stored', :aggregate_failures do
      expect(gql.result.data['active']).to be(true)
      expect(Chat::Agent.state(agent.id)).to be(true)
    end

    context 'when switching off' do
      let(:variables) { { active: false } }

      it 'returns the availability as stored' do
        expect(gql.result.data['active']).to be(false)
      end
    end

    context 'without the flag' do
      let(:variables) { {} }

      it 'is rejected by the schema' do
        expect(gql.result.error_message).to include('$active')
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
