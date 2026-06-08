# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::Tickets::Stats::MonthlyByCustomer, :aggregate_failures, type: :graphql do
  let(:query) do
    <<~QUERY
      query ticketsStatsMonthlyByCustomer($customerId: ID!) {
        ticketsStatsMonthlyByCustomer(customerId: $customerId) {
          monthNumber
          monthLabel
          year
          ticketsCreated
          ticketsClosed
        }
      }
    QUERY
  end
  let(:variables)        { { customerId: gql.id(customer_ticket.customer) } }
  let(:group)            { create(:group) }
  let(:customer)         { create(:customer) }
  let(:customer_ticket)  { create(:ticket, group:, customer:) }
  let(:user)             { create(:agent, groups: [group]) }

  before do
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    it 'returns data' do
      expect(gql.result.data.count).to eq(12)
      expect(gql.result.data.first).to match(
        {
          'monthLabel'     => be_a(String),
          'monthNumber'    => be_a(String),
          'ticketsClosed'  => 0,
          'ticketsCreated' => 1,
          'year'           => be_a(String),
        }
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
