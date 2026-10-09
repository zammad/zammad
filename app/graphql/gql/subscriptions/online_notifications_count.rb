# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OnlineNotificationsCount < BaseSubscription
    description 'Updates unseen notifications count'

    subscription_scope :current_user_id

    field :unseen_count, Integer, null: false, description: 'Count of unseen notifications for the user'
    field :unseen_push_tags, [String], null: false, description: 'Tags of the web pushes whose notifications the user has not seen yet, so a device can close the other ones'

    # Resolved per requested field, so a client that asks for the count alone
    #   does not pay for the tags.
    Payload = Struct.new(:unseen) do
      def unseen_count
        unseen.count
      end

      def unseen_push_tags
        OnlineNotification.push_tags(unseen).values.uniq
      end
    end

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
      Payload.new(scope.where(seen: false))
    end
  end
end
