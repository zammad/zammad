# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The X-Zammad-Suppress-Notifications header requires the full HTTP request
# cycle (around_action in HandlesTransitions), so this spec uses type: :request.
# What the job does with the flag is covered by spec/models/transaction/notification_spec.rb.
RSpec.describe Gql::Mutations::Ticket::Create, performs_jobs: true, type: :request do
  let(:group)    { Group.find_by(name: 'Users') }
  let(:agent)    { create(:agent, groups: [group]) }
  let(:customer) { create(:customer) }

  let(:gql_query) do
    <<~QUERY
      mutation ticketCreate($input: TicketCreateInput!) {
        ticketCreate(input: $input) {
          ticket { id internalId }
        }
      }
    QUERY
  end

  let(:variables) do
    {
      input: {
        title:    'GQL create suppress test',
        groupId:  Gql::ZammadSchema.id_from_object(group),
        customer: { id: Gql::ZammadSchema.id_from_object(customer) },
        article:  { body: 'some body' },
      },
    }
  end

  before do
    TransactionDispatcher.reset
    clear_jobs
    authenticated_as(agent)
  end

  describe 'X-Zammad-Suppress-Notifications header' do
    it 'enqueues the transaction job with disable_notification: true when header is set', :aggregate_failures do
      post '/graphql',
           params:  { query: gql_query, variables: variables },
           headers: { 'X-Zammad-Suppress-Notifications' => 'true' },
           as:      :json

      expect(json_response).not_to have_key('errors')
      expect(TransactionJob).to have_been_enqueued.with(anything, hash_including(disable_notification: true)).at_least(:once)
    end

    it 'enqueues the transaction job without disable_notification when header is absent', :aggregate_failures do
      post '/graphql',
           params: { query: gql_query, variables: variables },
           as:     :json

      expect(json_response).not_to have_key('errors')
      expect(TransactionJob).to have_been_enqueued.at_least(:once)
      expect(TransactionJob).not_to have_been_enqueued.with(anything, hash_including(disable_notification: true)).at_least(:once)
    end
  end
end
