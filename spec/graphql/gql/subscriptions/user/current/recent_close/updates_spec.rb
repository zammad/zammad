# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::RecentClose::Updates, authenticated_as: :agent, type: :graphql do
  let(:mock_channel) { build_mock_channel }
  let(:agent)        { create(:agent) }

  let(:subscription) do
    <<~QUERY
      subscription userCurrentRecentCloseUpdates {
        userCurrentRecentCloseUpdates {
          recentCloseUpdated
        }
      }
    QUERY
  end

  before do
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'when subscribed' do
    it 'subscribes' do
      expect(gql.result.data).to eq({ 'recentCloseUpdated' => nil })
    end

    it 'receives recent_view updates for the current user' do
      create(:recent_close, user: agent, recently_closed_object: agent)
      expect(mock_channel.mock_broadcasted_messages.first.dig(:result, 'data', 'userCurrentRecentCloseUpdates', 'recentCloseUpdated')).to be(true)
    end

    context 'when another user creates updates' do
      let(:other_user) { create(:agent) }

      it 'does not receive recent_view updates for another user' do
        create(:recent_close, user: other_user, recently_closed_object: agent)
        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end
  end
end
