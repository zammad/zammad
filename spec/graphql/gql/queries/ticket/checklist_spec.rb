# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Ticket::Checklist, type: :graphql do
  let(:group)     { create(:group) }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:ticket)    { create(:ticket, group: group) }
  let(:checklist) { create(:checklist, name: 'foobar', ticket: ticket) }

  let(:query) do
    <<~QUERY
      query ticketChecklist($ticketId: ID, $ticketInternalId: Int, $ticketNumber: String) {
        ticketChecklist(
          ticket: {
            ticketId: $ticketId
            ticketInternalId: $ticketInternalId
            ticketNumber: $ticketNumber
          }
        ) {
          id
          name
          completed
          items {
            id
            text
            checked
          }
        }
      }
    QUERY
  end

  let(:variables) { { ticketId: gql.id(ticket) } }

  let(:response) do
    {
      'id'        => gql.id(checklist),
      'name'      => checklist.name,
      'completed' => false,
      'items'     => checklist.items.map do |item|
        {
          'id'      => gql.id(item),
          'text'    => item.text,
          'checked' => item.checked,
        }
      end,
    }
  end

  before do
    checklist
    gql.execute(query, variables: variables)
  end

  shared_examples 'returning checklist data' do
    it 'returns checklist data' do
      expect(gql.result.data).to eq(response)
    end
  end

  shared_examples 'raising an error' do |error_type|
    it 'raises an error' do
      expect(gql.result.error_type).to eq(error_type)
    end
  end

  context 'with authenticated session', authenticated_as: :agent do
    it_behaves_like 'returning checklist data'

    context 'without access to the ticket' do
      let(:agent) { create(:agent) }

      it_behaves_like 'raising an error', Exceptions::Forbidden
    end

    context 'with ticket read permission' do
      let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

      it_behaves_like 'returning checklist data'
    end

    context 'when checklist does not exist' do
      let(:checklist) { nil }
      let(:response)  { nil }

      it_behaves_like 'returning checklist data'
    end

    context 'with alternative input variables' do
      context 'with internal ticket ID' do
        let(:variables) { { ticketInternalId: ticket.id } }

        it_behaves_like 'returning checklist data'
      end

      context 'with ticket number' do
        let(:variables) { { ticketNumber: ticket.number } }

        it_behaves_like 'returning checklist data'
      end

      context 'without any of required variables' do
        let(:variables) { {} }

        it_behaves_like 'raising an error', GraphQL::Schema::Validator::ValidationFailedError
      end
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
