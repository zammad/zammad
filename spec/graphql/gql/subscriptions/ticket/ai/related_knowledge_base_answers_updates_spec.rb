# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::Ticket::AI::RelatedKnowledgeBaseAnswersUpdates, authenticated_as: :agent, type: :graphql do
  let(:agent)        { create(:agent, groups: [ticket.group]) }
  let(:ticket)       { create(:ticket) }
  let(:variables)    { { ticketId: gql.id(ticket) } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~SUBSCRIPTION
      subscription ticketAIRelatedKnowledgeBaseAnswersUpdates($ticketId: ID!) {
        ticketAIRelatedKnowledgeBaseAnswersUpdates(ticketId: $ticketId) {
          ticketId
          error
        }
      }
    SUBSCRIPTION
  end

  before do
    setup_ai_provider('zammad_ai')

    gql.execute(subscription, variables:, context: { channel: mock_channel })
  end

  it 'subscribes without initial data' do
    expect(gql.result.data).to include('ticketId' => nil)
  end

  it 'delivers a ping pointing at the ticket (success, no error)' do
    described_class.trigger({ error: nil }, arguments: { ticket_id: gql.id(ticket) })

    expect(mock_channel.mock_broadcasted_messages.first).to include(
      result: include(
        'data' => include(
          'ticketAIRelatedKnowledgeBaseAnswersUpdates' => { 'ticketId' => gql.id(ticket), 'error' => nil }
        )
      )
    )
  end

  it 'delivers the error message when the embedding could not be produced' do
    described_class.trigger({ error: 'boom' }, arguments: { ticket_id: gql.id(ticket) })

    expect(mock_channel.mock_broadcasted_messages.first).to include(
      result: include(
        'data' => include(
          'ticketAIRelatedKnowledgeBaseAnswersUpdates' => { 'ticketId' => gql.id(ticket), 'error' => 'boom' }
        )
      )
    )
  end

  context 'when the agent lacks knowledge base permission' do
    let(:agent) { create(:agent, roles: [create(:role, permission_names: %w[ticket.agent])], groups: [ticket.group]) }

    it 'subscribes as well (they get published answers suggested)' do
      expect(gql.result.data).to include('ticketId' => nil)
    end
  end

  context 'when the user is no agent' do
    let(:agent) { create(:customer) }

    it 'is forbidden' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end
end
