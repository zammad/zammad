# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::ByFilter, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketsByFilter($customerId: ID, $stateTypeCategory: EnumTicketStateTypeCategory) {
        ticketsByFilter(customerId: $customerId, stateTypeCategory: $stateTypeCategory) {
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
  let(:customer)            { create(:customer) }
  let!(:customer_ticket)    { create(:ticket, group:, customer:) }
  let(:user)                { create(:agent, groups: [group]) }
  let(:state_type_category) { 'open' }

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    context 'without filters' do
      let(:variables) { {} }

      it 'returns an error' do
        expect(gql.result.error_type).to eq(Exceptions::UnprocessableEntity)
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
