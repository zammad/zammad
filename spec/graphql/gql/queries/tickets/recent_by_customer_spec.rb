# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::RecentByCustomer, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketsRecentByCustomer($customerId: ID!, $exceptTicketInternalId: Int) {
        ticketsRecentByCustomer(customerId: $customerId, exceptTicketInternalId: $exceptTicketInternalId) {
          id
        }
      }
    QUERY
  end
  let(:variables)        { { customerId: gql.id(customer), exceptTicketInternalId: ticket.id } }
  let(:group)            { create(:group) }
  let(:customer)         { create(:customer) }
  let(:ticket)           { create(:ticket, group:, customer:) }
  let!(:customer_ticket) { create(:ticket, group:, customer:) }
  let(:user)             { create(:agent, groups: [group]) }

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    it 'returns data' do
      expect(gql.result.data).to eq(
        [{ 'id' => gql.id(customer_ticket) }]
      )
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
