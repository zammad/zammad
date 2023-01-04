# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::AutocompleteSearch::MergeTicket, authenticated_as: :agent, type: :graphql do

  context 'when searching for merge tickets', searchindex: true do
    let(:group)         { create(:group) }
    let(:agent)         { create(:agent, groups: [group]) }
    let(:state)         { Ticket::State.find_by(name: 'open') }
    let(:source_ticket) { tickets.first }
    let!(:tickets) do
      create_list(:ticket, 3, group: group, state: state).each_with_index do |ticket, i|
        ticket.title = "TicketAutoComplete#{i}"
        ticket.save!
        create(:ticket_article, ticket: ticket)
      end
    end
    let(:query) do
      <<~QUERY
        query autocompleteSearchMergeTicket($input: AutocompleteSearchMergeTicketInput!)  {
          autocompleteSearchMergeTicket(input: $input) {
            value
            label
            heading
            ticket {
              number
            }
          }
        }
      QUERY
    end
    let(:variables)    { { input: { query: query_string, limit: limit, sourceTicketId: gql.id(source_ticket) } } }
    let(:query_string) { 'TicketAutoComplete' }
    let(:limit)        { nil }

    before do
      searchindex_model_reload([Ticket])
      gql.execute(query, variables: variables)
    end

    context 'with an agent' do

      context 'without limit' do
        it 'finds all tickets except the source ticket' do
          expect(gql.result.data.length).to eq(tickets.length - 1)
        end

        context 'with merged tickets' do
          let(:state) { Ticket::State.find_by(name: 'merged') }

          it 'does not find merged tickets' do
            expect(gql.result.data).to be_empty
          end
        end
      end

      context 'without change permission' do
        let(:agent) { create(:agent, groups: [group], group_names_access_map: { group.name => 'read' }) }

        it 'finds no tickets' do
          expect(gql.result.data).to be_empty
        end
      end

      context 'with limit' do
        let(:limit) { 1 }

        it 'respects the limit' do
          expect(gql.result.data.length).to eq(limit)
        end
      end

      context 'with exact search' do
        let(:second_ticket_payload) do
          {
            'value'   => gql.id(tickets.second),
            'label'   => tickets.second.title,
            'heading' => "##{tickets.second.number} · #{tickets.second.customer.fullname}",
            'ticket'  => { 'number' => tickets.second.number },
          }
        end
        let(:query_string) { tickets.second.number }

        it 'has data' do
          expect(gql.result.data).to eq([second_ticket_payload])
        end
      end

      context 'when sending an empty search string' do
        let(:query_string) { '   ' }

        it 'still returns tickets, but not the source ticket' do
          expect(gql.result.data.length).to eq(tickets.length - 1)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }

      it 'raises authorization error' do
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end
end
