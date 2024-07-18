# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::TaskbarItemUpdates, type: :graphql do
  let(:user)         { create(:agent) }
  let(:app)          { 'desktop' }
  let(:variables)    { { userId: gql.id(user), app: app } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription userCurrentTaskbarItemUpdates($userId: ID!, $app: EnumTaskbarApp!) {
        userCurrentTaskbarItemUpdates(userId: $userId, app: $app) {
          addItem {
            app
            key
          }
          updateItem {
            app
            key
          }
          removeItem
        }
      }
    QUERY
  end

  context 'with not authenticated user' do
    it 'does not subscribe to taskbar item updates and returns an authorization error' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.error_type).to eq(Exceptions::NotAuthorized)
    end
  end

  context 'with authenticated user', authenticated_as: :user do
    it 'subscribes to taskbar item updates' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.data).not_to be_nil
    end

    it 'triggers after create' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      create(:taskbar, user_id: user.id, app: app, key: 'key')

      result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemUpdates']
      expect(result).to eq(
        { 'addItem' => { 'app' => app, 'key' => 'key' }, 'removeItem' => nil, 'updateItem' => nil }
      )
    end

    it 'triggers after update' do
      item = create(:taskbar, user_id: user.id, app: app, key: 'key')

      gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      item.update!(key: 'new_key')

      result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemUpdates']
      expect(result).to eq(
        { 'addItem' => nil, 'removeItem' => nil, 'updateItem' => { 'app' => app, 'key' => 'new_key' } }
      )
    end

    it 'triggers after remove' do
      item = create(:taskbar, user_id: user.id, app: app, key: 'key')

      gql.execute(subscription, variables: variables, context: { channel: mock_channel })
      gid = Gql::ZammadSchema.id_from_object(item)
      item.destroy!

      result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemUpdates']
      expect(result).to eq(
        { 'addItem' => nil, 'removeItem' => gid, 'updateItem' => nil }
      )
    end

    context 'with different target app' do
      let(:app) { 'mobile' }

      it 'does not trigger' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })

        create(:taskbar, user_id: user.id, app: 'desktop', key: 'key')

        expect(mock_channel.mock_broadcasted_messages).to be_empty
      end
    end

    context 'with different target user' do
      let(:another_user) { create(:agent) }
      let(:variables)    { { userId: gql.id(another_user), app: app } }

      it 'does not subscribe to taskbar item updates and returns a forbidden error' do
        gql.execute(subscription, variables: variables, context: { channel: mock_channel })

        expect(gql.result.error_type).to eq(Exceptions::Forbidden)
      end
    end
  end
end
