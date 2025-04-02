# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::RecentView::Updates, authenticated_as: :agent, type: :graphql do
  let(:mock_channel)              { build_mock_channel }
  let(:agent)                     { create(:agent) }
  let(:subscription) do
    <<~QUERY
      subscription userCurrentRecentViewUpdates {
        userCurrentRecentViewUpdates {
          recentViewsUpdated
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'recentViewsUpdated' => nil })
    end

    it 'receives recent_view updates for the current user' do
      RecentView.log('User', agent.id, agent)
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'userCurrentRecentViewUpdates', 'recentViewsUpdated')).to be(true)
    end

    context 'when another user creates updates' do
      let(:other_user) { create(:agent) }

      it 'does not receive recent_view updates for another user' do
        UserInfo.current_user_id = other_user.id # Required to set created_by_id to this user.
        RecentView.log('User', agent.id, other_user)
        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end
end
