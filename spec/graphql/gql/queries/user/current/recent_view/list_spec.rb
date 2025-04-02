# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::RecentView::List, type: :graphql do
  let(:query) do
    <<~QUERY
      query userCurrentRecentViewList($limit: Int) {
        userCurrentRecentViewList(limit: $limit) {
          __typename
          ... on Ticket {
            id
          }
          ... on User {
            id
          }
          ... on Organization {
            id
          }
        }
      }
    QUERY
  end
  let(:limit)                        { nil }
  let(:variables)                    { { limit: limit } }
  let(:group)                        { create(:group) }
  let(:customer)                     { create(:customer) }
  let(:ticket)                       { create(:ticket, group:, customer:) }
  let(:inaccessible_customer_ticket) { create(:ticket, customer:) }
  let(:user)                         { create(:agent, groups: [group]) }

  before do
    RecentView.log('Ticket', ticket.id, user)
    RecentView.log('User', customer.id, user)
    RecentView.log('Ticket', inaccessible_customer_ticket.id, user)
    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    it 'returns data' do
      expect(gql.result.data).to eq(
        [
          { '__typename' => 'User', 'id' => gql.id(customer) },
          { '__typename' => 'Ticket', 'id' => gql.id(ticket) },
        ]
      )
    end

    context 'with a limit' do
      let(:limit) { 1 }

      it 'respects the limit' do
        expect(gql.result.data).to eq(
          [
            { '__typename' => 'User', 'id' => gql.id(customer) },
          ]
        )
      end
    end
  end

  context 'with a customer', authenticated_as: :user do
    let(:user) { customer }

    it 'returns data' do
      expect(gql.result.data).to eq(
        [
          { '__typename' => 'Ticket', 'id' => gql.id(inaccessible_customer_ticket) },
          { '__typename' => 'User', 'id' => gql.id(customer) },
          { '__typename' => 'Ticket', 'id' => gql.id(ticket) },
        ]
      )
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
