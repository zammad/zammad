# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Queries::User::Current::RecentClose::List, type: :graphql do
  let(:limit)                                     { nil }
  let(:variables)                                 { { limit: limit } }
  let(:group)                                     { create(:group) }
  let(:customer)                                  { create(:customer) }
  let(:ticket)                                    { create(:ticket, group:, customer:) }
  let(:inaccessible_customer_ticket)              { create(:ticket, customer:) }
  let(:user)                                      { create(:agent, groups: [group]) }
  let(:recent_close_ticket)                       { create(:recent_close, user:, recently_closed_object: ticket, updated_at: 1.minute.ago) }
  let(:recent_close_user)                         { create(:recent_close, user:, recently_closed_object: customer) }
  let(:recent_close_inaccessible_customer_ticket) { create(:recent_close, user: customer, recently_closed_object: inaccessible_customer_ticket) }

  let(:query) do
    <<~QUERY
      query userCurrentRecentCloseList($limit: Int) {
        userCurrentRecentCloseList(limit: $limit) {
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

  before do
    recent_close_ticket && recent_close_user && recent_close_inaccessible_customer_ticket

    gql.execute(query, variables: variables)
  end

  context 'with an agent', authenticated_as: :user do
    it 'returns expected data' do
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

  context 'with an admin without agent permissions', authenticated_as: :user do
    let(:admin) { create(:admin) }
    let(:user)  { admin }

    before do
      admin.roles.each { |role| role.permission_revoke('ticket.agent') }
      admin.reload

      # Re-run the query with updated permissions; existing recent_closes for this user
      gql.execute(query, variables: variables)
    end

    it 'returns data without tickets' do
      expect(gql.result.data).to eq(
        [
          { '__typename' => 'User', 'id' => gql.id(customer) },
        ]
      )
    end
  end

  it_behaves_like 'graphql responds with error if unauthenticated'
end
