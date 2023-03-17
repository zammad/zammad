# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::Ticket::CustomerUpdate, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      mutation ticketCustomerUpdate($ticketId: ID!, $input: TicketCustomerUpdateInput!) {
        ticketCustomerUpdate(ticketId: $ticketId, input: $input) {
          ticket {
            id
            customer {
              fullname
            }
            organization {
              name
            }
          }
          errors {
            message
            field
          }
        }
      }
    QUERY
  end
  let(:agent)         { create(:agent, groups: [ Group.find_by(name: 'Users')]) }
  let(:customer)      { create(:customer, organization: organization) }
  let(:organization)  { create(:organization) }
  let(:group)         { agent.groups.first }
  let(:ticket)        { create(:ticket, group: agent.groups.first, customer: customer) }
  let(:input_payload) { { customerId: gql.id(customer), organizationId: gql.id(organization) } }
  let(:variables)     { { ticketId: gql.id(ticket), input: input_payload } }
  let(:expected_base_response) do
    {
      'id'           => gql.id(Ticket.last),
      'customer'     => { 'fullname' => customer.fullname },
      'organization' => { 'name' => organization.name },
    }
  end

  let(:expected_response) do
    expected_base_response
  end

  context "when updating a ticket's customer" do
    context 'with an agent', authenticated_as: :agent do
      it 'updates customer and organization' do
        gql.execute(query, variables: variables)
        expect(gql.result.data['ticket']).to eq(expected_response)
      end

      context 'without organization' do
        let(:customer) { create(:customer) }
        let(:input_payload)     { { customerId: gql.id(customer) } }
        let(:expected_response) { expected_base_response.tap { |res| res['organization'] = nil } }

        it 'updates the customer' do
          gql.execute(query, variables: variables)
          expect(gql.result.data['ticket']).to eq(expected_response)
        end
      end
    end

    context 'with a customer', authenticated_as: :customer do
      it 'raises an error', :aggregate_failures do
        gql.execute(query, variables: variables)
        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
        expect(gql.result.error_message).to eq("Failed Gql::EntryPoints::Mutations's authorization check on field ticketCustomerUpdate")
      end
    end
  end
end
