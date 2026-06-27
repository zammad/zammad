# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The X-Zammad-Suppress-Notifications header requires the full HTTP request
# cycle (around_action in HandlesTransitions), so this spec uses type: :request.
RSpec.describe Gql::Mutations::Ticket::Update, type: :request do
  let(:agent)  { create(:agent, groups: [Group.find_by(name: 'Users')]) }
  let(:ticket) { create(:ticket, group: agent.groups.first) }

  let(:gql_query) do
    <<~QUERY
      mutation ticketUpdate($ticketId: ID!, $input: TicketUpdateInput!) {
        ticketUpdate(ticketId: $ticketId, input: $input) {
          ticket { id }
        }
      }
    QUERY
  end

  before do
    allow(TransactionDispatcher).to receive(:commit).and_call_original
    authenticated_as(agent)
  end

  describe 'X-Zammad-Suppress-Notifications header' do
    it 'passes disable_notification: true to dispatcher when header is set' do
      post '/graphql',
           params:  { query: gql_query, variables: { ticketId: Gql::ZammadSchema.id_from_object(ticket), input: { title: 'GQL suppress test' } } },
           headers: { 'X-Zammad-Suppress-Notifications' => 'true' },
           as:      :json

      expect(TransactionDispatcher).to have_received(:commit).with(hash_including(disable_notification: true)).at_least(:once)
    end

    it 'does not pass disable_notification when header is absent' do
      post '/graphql',
           params: { query: gql_query, variables: { ticketId: Gql::ZammadSchema.id_from_object(ticket), input: { title: 'GQL no suppress test' } } },
           as:     :json

      expect(TransactionDispatcher).not_to have_received(:commit).with(hash_including(disable_notification: true))
    end
  end
end
