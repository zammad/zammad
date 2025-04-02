# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OnlineNotificationsCount < BaseSubscription
    description 'Updates unseen notifications count'

    subscription_scope :current_user_id

    field :unseen_count, Integer, null: false, description: 'Count of unseen notifications for the user'

    def subscribe
      response
    end

    def update
      response
    end

    private

    def scope
      OnlineNotification.where(user: context.current_user)
    end

    def response
      {
        unseen_count: scope.where(seen: false).count,
      }
    end
  end
end
