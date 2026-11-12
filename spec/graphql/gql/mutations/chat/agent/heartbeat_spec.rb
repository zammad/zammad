# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The behavior is covered by spec/services/service/chat/agent/heartbeat_spec.rb —
#   this covers the GraphQL surface only.
RSpec.describe Gql::Mutations::Chat::Agent::Heartbeat, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation chatAgentHeartbeat {
        chatAgentHeartbeat {
          success
          errors {
            message
            field
          }
        }
      }
    GQL
  end

  let(:chat_enabled) { true }
  let(:agent)        { create(:agent) }

  before do
    Setting.set('chat', chat_enabled)
    gql.execute(mutation)
  end

  context 'with a chat agent', authenticated_as: :agent do
    it 'succeeds and records the agent', :aggregate_failures do
      expect(gql.result.data['success']).to be(true)
      expect(Chat::Agent.find_by(updated_by_id: agent.id)).to be_present
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
