# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::RecentView::Reset, :aggregate_failures, type: :graphql do
  let(:mutation) do
    <<~GQL
      mutation userCurrentRecentViewReset {
        userCurrentRecentViewReset {
          success
        }
      }
    GQL
  end

  let(:group)                        { create(:group) }
  let(:ticket)                       { create(:ticket, group:) }
  let(:user)                         { create(:agent, groups: [group]) }

  def execute_graphql_query
    gql.execute(mutation)
  end

  context 'when user is authenticated', authenticated_as: :user do
    before do
      RecentView.log('Ticket', ticket.id, user)
      RecentView.log('User', user.id, user)
      allow(Gql::Subscriptions::User::Current::RecentView::Updates).to receive(:trigger)
    end

    it 'resets recent view entries' do
      execute_graphql_query
      expect(gql.result.data[:success]).to be(true)
      expect(RecentView.list(user)).to be_empty
    end

    it 'triggers the recent view updates subscription only once' do
      execute_graphql_query
      expect(Gql::Subscriptions::User::Current::RecentView::Updates).to have_received(:trigger).exactly(1).with({}, scope: user.id)
    end
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end
end
