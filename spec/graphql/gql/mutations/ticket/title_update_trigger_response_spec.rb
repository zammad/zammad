# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Trigger dispatch ordering depends on the full HTTP request cycle
# (around_action in HandlesTransitions), so this spec uses type: :request.
RSpec.describe Gql::Mutations::Ticket::TitleUpdate, type: :request do
  let(:group)         { Group.find_by(name: 'Users') }
  let(:agent)         { create(:agent, groups: [group]) }
  let(:ticket)        { create(:ticket, group: group) }
  let(:high_priority) { Ticket::Priority.find_by(name: '3 high') }

  let(:trigger) do
    create(:trigger,
           :conditionable,
           condition_ticket_action:  :update,
           execution_condition_mode: 'always',
           perform:                  { 'ticket.priority_id' => { 'value' => high_priority.id.to_s } })
  end

  let(:gql_query) do
    <<~QUERY
      mutation ticketTitleUpdate($ticketId: ID!, $title: String!) {
        ticketTitleUpdate(ticketId: $ticketId, title: $title) {
          ticket { title priority { name } }
          errors { message field }
        }
      }
    QUERY
  end

  before do
    ticket
    trigger
    # Drop buffered events from factory creation, so the request's update
    # event is not merged into a leftover create event.
    TransactionDispatcher.reset
    authenticated_as(agent)
  end

  describe 'trigger results in title update response' do
    # Sync triggers are dispatched inside the forced update service's
    # Transaction.execute, before the mutation result is built - their changes
    # must be part of it.
    it 'returns attributes changed by triggers' do
      post '/graphql',
           params: {
             query:     gql_query,
             variables: { ticketId: Gql::ZammadSchema.id_from_object(ticket), title: 'trigger me' },
           },
           as:     :json

      expect(json_response.dig('data', 'ticketTitleUpdate', 'ticket', 'priority', 'name')).to eq(high_priority.name)
    end
  end
end
