# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::AvatarUpdates, type: :graphql do

  let(:subscription) do
    <<~QUERY
      subscription userCurrentAvatarUpdates {
        userCurrentAvatarUpdates {
          avatars {
            id
            default
            deletable
            initial
            imageHash
            createdAt
            updatedAt
          }
        }
      }
    QUERY
  end
  let(:mock_channel) { build_mock_channel }
  let(:target)       { create(:user) }
  let(:avatar)       { create(:avatar, o_id: target.id, default: false, initial: true) }

  context 'when user is authenticated, but has no permission', authenticated_as: :agent do
    let(:agent) { create(:agent, roles: []) }

    before do
      gql.execute(subscription, context: { channel: mock_channel })
    end

    it_behaves_like 'graphql responds with error if unauthenticated'
  end

  context 'with authenticated user', authenticated_as: :target do
    it 'subscribes' do
      gql.execute(subscription, context: { channel: mock_channel })
      expect(gql.result.data).to eq({ 'avatars' => nil })
    end

    it 'receives avatar updates for target user' do
      gql.execute(subscription, context: { channel: mock_channel })
      avatar.update!(default: true)
      expect(mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentAvatarUpdates']['avatars'].count).to eq(1)
    end

    it 'does not receive avatar updates for other users' do
      gql.execute(subscription, context: { channel: mock_channel })
      another_user = create(:user)
      another_avatar = create(:avatar, o_id: another_user.id, default: false)
      another_avatar.update!(default: true)
      expect(mock_channel.mock_broadcasted_messages).to be_empty
    end
  end
end
