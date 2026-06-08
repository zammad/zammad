# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::ByCustomer, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketsByCustomer(
        $customerId: ID!
        $customerOrganizations: Boolean
        $stateTypeCategory: EnumTicketStateTypeCategory
      ) {
        ticketsByCustomer(
          customerId: $customerId
          customerOrganizations: $customerOrganizations
          stateTypeCategory: $stateTypeCategory
        ) {
          edges {
            node {
              id
            }
          }
          totalCount
        }
      }
    QUERY
  end
  let(:variables)           { { customerId: gql.id(customer), stateTypeCategory: state_type_category } }
  let(:group)               { create(:group) }
  let(:organization)        { create(:organization, shared: true) }
  let(:customer)            { create(:customer, organization:) }
  let!(:customer_ticket)    { create(:ticket, group:, customer:, organization:) }
  let(:user)                { create(:agent, groups: [group]) }
  let(:state_type_category) { 'open' }

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    context 'without customer filter' do
      let(:variables) { {} }

      it 'returns an error' do
        expect(gql.result.error_message).to eq('Variable $customerId of type ID! was provided invalid value')
      end
    end

    context 'with a customer and a state type category' do
      context 'with matching tickets' do
        it 'returns data' do
          expect(gql.result.data).to eq(
            {
              'edges'      => [
                { 'node' => { 'id' => gql.id(customer_ticket) } }
              ],
              'totalCount' => 1
            }
          )
        end
      end

      context 'without matching tickets' do
        let(:state_type_category) { 'closed' }

        it 'returns empty data' do
          expect(gql.result.data).to eq(
            {
              'edges'      => [],
              'totalCount' => 0
            }
          )
        end
      end

      context "with customer's organizations only" do
        let(:variables) { { customerId: gql.id(customer), customerOrganizations: true, stateTypeCategory: state_type_category } }

        context 'with matching tickets' do
          it 'returns data' do
            expect(gql.result.data).to eq(
              {
                'edges'      => [
                  { 'node' => { 'id' => gql.id(customer_ticket) } },
                ],
                'totalCount' => 1
              }
            )
          end
        end

        context 'without matching tickets' do
          let(:state_type_category) { 'closed' }

          it 'returns empty data' do
            expect(gql.result.data).to eq(
              {
                'edges'      => [],
                'totalCount' => 0
              }
            )
          end
        end

        context 'with customer without organization' do
          let(:customer_without_org) { create(:customer, organization: nil) }
          let(:customer_without_org_2) { create(:customer, organization: nil) }
          let(:ticket_without_org)     { create(:ticket, group:, customer: customer_without_org, organization: nil) }
          let(:ticket_without_org_2)   { create(:ticket, group:, customer: customer_without_org_2, organization: nil) }
          let(:variables)              { { customerId: gql.id(customer_without_org), customerOrganizations: true, stateTypeCategory: state_type_category } }

          it 'returns no tickets from other users without organization' do
            expect(gql.result.data).to eq(
              {
                'edges'      => [],
                'totalCount' => 0
              }
            )
          end
        end
      end
    end
  end

  context 'with a customer', authenticated_as: :user do
    let(:user) { create(:customer) }

    it 'raises an error' do
      expect(gql.result.error_type).to eq(Exceptions::Forbidden)
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
