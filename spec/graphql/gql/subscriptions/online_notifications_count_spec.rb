# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::OnlineNotificationsCount, authenticated_as: :agent, type: :graphql do
  let(:agent)        { create(:agent) }
  let(:notification) { create(:online_notification, user_id: agent.id) }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription onlineNotificationsCount {
        onlineNotificationsCount {
          unseenCount
        }
      }
    QUERY
  end

  before do
    notification
    gql.execute(subscription, context: { channel: mock_channel })
  end

  context 'with an agent' do
    context 'with matching user' do
      let(:user) { agent }

      before { travel 10.minutes }

      it 'subscribes' do
        expect(gql.result.data).to eq({ 'unseenCount' => 1 })
      end

      it 'receives update when new notification created' do
        create(:online_notification, user_id: agent.id)

        expect(mock_channel.mock_broadcasted_first.data).to include('unseenCount' => 2)
      end

      it 'receives update when existing notification marked as seen' do
        notification.update! seen: true

        expect(mock_channel.mock_broadcasted_first.data).to include('unseenCount' => 0)
      end
    end
  end
end
