# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::DevicesUpdates, type: :graphql do
  let(:subscription) do
    <<~QUERY
      subscription userCurrentDevicesUpdates {
        userCurrentDevicesUpdates {
          devices {
            name
          }
        }
      }
    QUERY
  end

  let(:mock_channel) { build_mock_channel }
  let(:target)       { create(:agent) }

  context 'with authenticated user', authenticated_as: :target do
    it 'subscribes' do
      gql.execute(subscription, context: { channel: mock_channel })
      expect(gql.result.data).to eq({ 'devices' => nil })
    end

    it 'receives user device updates for target user' do
      gql.execute(subscription, context: { channel: mock_channel })
      create(:user_device, user_id: target.id)
      expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentDevicesUpdates']['devices'].count).to eq(1)
    end

    it 'does not receive user device updates for other users' do
      gql.execute(subscription, context: { channel: mock_channel })
      create(:user_device, user_id: create(:agent).id)
      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end
end
