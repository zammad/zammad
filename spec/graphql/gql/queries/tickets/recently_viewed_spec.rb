# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::RecentlyViewed, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketsRecentlyViewed($exceptTicketInternalId: Int) {
        ticketsRecentlyViewed(exceptTicketInternalId: $exceptTicketInternalId) {
          id
        }
      }
    QUERY
  end
  let(:variables)                    { { exceptTicketInternalId: ticket.id } }
  let(:group)                        { create(:group) }
  let(:customer)                     { create(:customer) }
  let(:ticket)                       { create(:ticket, group:, customer:) }
  let(:customer_ticket)              { create(:ticket, group:, customer:) }
  let(:inaccessible_customer_ticket) { create(:ticket, customer:) }
  let(:user)                         { create(:agent, groups: [group]) }

  before do
    RecentView.log('Ticket', ticket.id, user)
    RecentView.log('Ticket', customer_ticket.id, user)
    RecentView.log('Ticket', inaccessible_customer_ticket.id, user)
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
