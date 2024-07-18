# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::TaskbarItemUpdates < BaseSubscription

    description 'Changes to the list of taskbar items of the currently logged-in user'

    argument :user_id, GraphQL::Types::ID, loads: Gql::Types::UserType, description: 'Filter by user'
    argument :app, Gql::Types::Enum::TaskbarAppType, description: 'Filter by app'

    field :add_item, Gql::Types::User::TaskbarItemType, description: 'A new taskbar item needs to be added to the list'
    field :update_item, Gql::Types::User::TaskbarItemType, description: 'An existing taskbar item was changed'
    field :remove_item, GraphQL::Types::ID, description: 'An item must be removed from the list'

    class << self
      def trigger_after_create(item)
        pull_trigger(item, { add_item: item })
      end

      def trigger_after_update(item)
        pull_trigger(item, { update_item: item })
      end

      def trigger_after_destroy(item)
        pull_trigger(item, { remove_item: Gql::ZammadSchema.id_from_object(item) })
      end

      def pull_trigger(item, payload)
        user_id = Gql::ZammadSchema.id_from_internal_id(::User, item.user_id)

        trigger(payload, arguments: { user_id:, app: item.app })
      end
    end

    def authorized?(user:, app:)
      user == context.current_user
    end

    def update(user:, app:)
      object
    end

  end
end
