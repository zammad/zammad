# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Gql::Subscriptions::User::Current::TaskbarItem::ListUpdates, type: :graphql do
  let(:user)         { create(:agent) }
  let(:variables)    { { userId: gql.id(user), app: 'desktop' } }
  let(:mock_channel) { build_mock_channel }
  let(:subscription) do
    <<~QUERY
      subscription userCurrentTaskbarItemListUpdates($userId: ID!, $app: EnumTaskbarApp!) {
        userCurrentTaskbarItemListUpdates(userId: $userId, app: $app) {
          taskbarItemList {
            id
          }
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
    it 'subscribes to taskbar item list update (prio)' do
      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      expect(gql.result.data).not_to be_nil
    end

    it 'triggers after taskbar item list update (prio)', :aggregate_failures do
      items = create_list(:taskbar, 3, user_id: user.id, app: 'desktop')

      gql.execute(subscription, variables: variables, context: { channel: mock_channel })

      order = items.map do |item|
        { id: item.id, prio: Faker::Number.unique.between(from: 1, to: 10) }
      end
      Taskbar.reorder_list(user, order)

      result = mock_channel.mock_broadcasted_messages.first[:result]['data']['userCurrentTaskbarItemListUpdates']
      expect(result).to include('taskbarItemList')

      list = Taskbar.list(user, app: 'desktop')
      ids = result['taskbarItemList'].pluck('id').map { |gid| Gql::ZammadSchema.verified_object_from_id(gid, type: Taskbar).id }
      expect(ids).to eq(list.map(&:id))
    end
  end
end
