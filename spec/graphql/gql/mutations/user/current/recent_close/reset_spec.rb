# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Mutations::User::Current::RecentClose::Reset, :aggregate_failures, type: :graphql do
  let(:group)               { create(:group) }
  let(:ticket)              { create(:ticket, group:) }
  let(:user)                { create(:agent, groups: [group]) }
  let(:recent_close_ticket) { create(:recent_close, user:, recently_closed_object: ticket) }
  let(:recent_close_user)   { create(:recent_close, user:, recently_closed_object: user) }

  let(:mutation) do
    <<~GQL
      mutation userCurrentRecentCloseReset {
        userCurrentRecentCloseReset {
          success
        }
      }
    GQL
  end

  def execute_graphql_query
    gql.execute(mutation)
  end

  context 'when user is authenticated', authenticated_as: :user do
    before do
      recent_close_ticket && recent_close_user
      allow(Gql::Subscriptions::User::Current::RecentClose::Updates).to receive(:trigger)
    end

    it 'resets recent view entries' do
      execute_graphql_query
      expect(gql.result.data[:success]).to be(true)
      expect(user.recent_closes).to be_empty
    end

    it 'triggers the recent view updates subscription only once' do
      execute_graphql_query
      expect(Gql::Subscriptions::User::Current::RecentClose::Updates).to have_received(:trigger).exactly(1).with({}, scope: user.id)
    end
  end

  context 'when user is not authenticated' do
    it 'returns an error' do
      expect(execute_graphql_query.error_message).to eq('Authentication required')
    end
  end
end
