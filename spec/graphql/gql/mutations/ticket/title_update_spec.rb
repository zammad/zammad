# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::TitleUpdate, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketTitleUpdate($ticketId: ID!, $input: TicketTitleUpdateInput!) {
        ticketTitleUpdate(ticketId: $ticketId, input: $input) {
          ticket {
            id
            title
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:agent)         { create(:agent, groups: [ticket.group]) }
  let(:title)         { 'Updated Ticket Title' }
  let(:ticket)        { create(:ticket) }
  let(:input_payload) { { title: } }
  let(:variables)     { { ticketId: gql.id(ticket), input: input_payload } }
  let(:expected_base_response) do
    {
      'id'    => gql.id(Ticket.last),
      'title' => title,
    }
  end

  let(:expected_response) do
    expected_base_response
  end

  context "when updating a ticket's customer" do
    context 'with an agent', authenticated_as: :agent do
      it 'updates title' do
        gql.execute(query, variables: variables)
        expect(gql.result.data[:ticket]).to eq(expected_response)
      end

      it 'uses forced update service' do
        allow(Service::Ticket::ForcedUpdate).to receive(:new).and_call_original

        gql.execute(query, variables: variables)

        expect(Service::Ticket::ForcedUpdate)
          .to have_received(:new)
          .with(ticket, { title: })
      end
    end

    context 'with a customer', authenticated_as: :customer do
      let(:customer) { create(:agent) }

      it 'raises an error', :aggregate_failures do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
