# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# The X-Zammad-Suppress-Notifications header requires the full HTTP request
# cycle (around_action in HandlesTransitions), so this spec uses type: :request.
RSpec.describe Gql::Mutations::Ticket::Create, performs_jobs: true, type: :request do
  let(:group) { Group.find_by(name: 'Users') }
  let(:agent) { create(:agent, groups: [group]) }
  let(:other_agent) do
    create(:agent, :preferencable, groups: [group], notification_group_ids: [group.id])
  end
  let(:customer)         { create(:customer) }
  let(:delivered_emails) { [] }

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
    allow(NotificationFactory::Mailer).to receive(:deliver) { |data| delivered_emails << data }
    other_agent
    TransactionDispatcher.reset
    clear_jobs
    authenticated_as(agent)
  end

  describe 'X-Zammad-Suppress-Notifications header' do
    it 'does not notify group agents when header is set', :aggregate_failures do
      post '/graphql',
           params:  { query: gql_query, variables: variables },
           headers: { 'X-Zammad-Suppress-Notifications' => 'true' },
           as:      :json

      perform_enqueued_jobs(only: TransactionJob)

      expect(json_response).not_to have_key('errors')

      ticket_id = json_response.dig('data', 'ticketCreate', 'ticket', 'internalId')
      expect(OnlineNotification.where(object_lookup_id: ObjectLookup.by_name('Ticket'), user_id: other_agent.id, o_id: ticket_id)).to be_empty
      expect(delivered_emails).to be_empty
    end

    it 'notifies group agents when header is absent', :aggregate_failures do
      post '/graphql',
           params: { query: gql_query, variables: variables },
           as:     :json

      perform_enqueued_jobs(only: TransactionJob)

      expect(json_response).not_to have_key('errors')

      ticket_id = json_response.dig('data', 'ticketCreate', 'ticket', 'internalId')
      expect(OnlineNotification.where(object_lookup_id: ObjectLookup.by_name('Ticket'), user_id: other_agent.id, o_id: ticket_id)).to exist
      expect(delivered_emails).to include(hash_including(recipient: have_attributes(email: other_agent.email)))
    end
  end
end
