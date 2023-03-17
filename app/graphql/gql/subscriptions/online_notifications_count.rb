# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OnlineNotificationsCount < BaseSubscription
    description 'Updates unseen notifications count'

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive updates for', loads: Gql::Types::UserType

    field :unseen_count, Integer, null: false, description: 'Count of unseen notifications for the user'

    # Allow subscriptions only for users where the current user has read permission for.
    def authorized?(user:)
      context.current_user == user
    end

    def subscribe(user:)
      response(user)
    end

    def update(user:)
      response(user)
    end

    private

    def scope(user)
      OnlineNotification.where(user: user)
    end

    def response(user)
      {
        unseen_count: scope(user).where(seen: false).count,
      }
    end
  end
end
