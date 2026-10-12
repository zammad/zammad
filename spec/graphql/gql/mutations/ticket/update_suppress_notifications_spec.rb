# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The X-Zammad-Suppress-Notifications header requires the full HTTP request
# cycle (around_action in HandlesTransitions), so this spec uses type: :request.
# What the job does with the flag is covered by spec/models/transaction/notification_spec.rb.
RSpec.describe Gql::Mutations::Ticket::Update, performs_jobs: true, type: :request do
  let(:group) { Group.find_by(name: 'Users') }
  let(:agent) { create(:agent, groups: [group]) }
  let(:owner) do
    create(:agent, :preferencable, groups: [group], notification_group_ids: [group.id])
  end
  let(:ticket) do
    create(:ticket, group:, owner:, created_by: owner, updated_by: owner)
  end

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
    ticket
    TransactionDispatcher.reset
    clear_jobs
    authenticated_as(agent)
  end

  describe 'X-Zammad-Suppress-Notifications header' do
    it 'enqueues the transaction job with disable_notification: true when header is set' do
      post '/graphql',
           params:  { query: gql_query, variables: { ticketId: Gql::ZammadSchema.id_from_object(ticket), input: { title: 'GQL suppress test' } } },
           headers: { 'X-Zammad-Suppress-Notifications' => 'true' },
           as:      :json

      expect(TransactionJob).to have_been_enqueued.with(anything, hash_including(disable_notification: true)).at_least(:once)
    end

    it 'enqueues the transaction job without disable_notification when header is absent', :aggregate_failures do
      post '/graphql',
           params: { query: gql_query, variables: { ticketId: Gql::ZammadSchema.id_from_object(ticket), input: { title: 'GQL no suppress test' } } },
           as:     :json

      expect(TransactionJob).to have_been_enqueued.at_least(:once)
      expect(TransactionJob).not_to have_been_enqueued.with(anything, hash_including(disable_notification: true)).at_least(:once)
    end
  end
end
