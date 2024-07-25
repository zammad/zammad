# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TaskbarItem::ListUpdates < BaseSubscription

    description 'Subscription for taskbar item list priority changes'

    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'Filter by user'

    field :taskbar_item_list, [Gql::Types::User::TaskbarItemType], description: 'List of taskbar items'

    def authorized?(user:)
      user == context.current_user
    end

    def update(user:)
      { taskbar_item_list: Taskbar.list(user) }
    end

  end
end
