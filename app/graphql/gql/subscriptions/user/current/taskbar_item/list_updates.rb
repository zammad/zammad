# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TaskbarItem::ListUpdates < BaseSubscription

    description 'Subscription for taskbar item list priority changes'

    subscription_scope :current_user_id

    argument :app, Gql::Types::Enum::TaskbarAppType, description: 'Taskbar app to filter for.'

    field :taskbar_item_list, [Gql::Types::User::TaskbarItemType], description: 'List of taskbar items'

    def update(app:)
      { taskbar_item_list: TaskbarPolicy::Scope.new(context.current_user, ::Taskbar).resolve.app(app) }
    end

  end
end
