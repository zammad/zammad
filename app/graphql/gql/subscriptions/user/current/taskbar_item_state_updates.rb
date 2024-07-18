# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TaskbarItemStateUpdates < BaseSubscription

    description 'Changes to the state of a taskbar item of the currently logged-in user'

    argument :taskbar_item_id, GraphQL::Types::ID, required: true, loads: Gql::Types::User::TaskbarItemType, description: 'The taskbar item ID'

    field :state_changed, Boolean, description: 'Signals that the taskbar item state has changed'

    def authorized?(taskbar_item:)
      taskbar_item.present? && taskbar_item.user_id == context.current_user.id
    end

    def update(taskbar_item:)
      { state_changed: true }
    end
  end
end
