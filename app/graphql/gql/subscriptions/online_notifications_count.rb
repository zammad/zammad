# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class OnlineNotificationsCount < BaseSubscription
    include Gql::Concerns::HandlesOnlineNotificationList

    description 'Updates unseen notifications count'

    subscription_scope :current_user_id

    field :unseen_count, Integer, null: false, description: 'Count of unseen notifications for the user'
    field :unseen_push_tags, [String], null: false, description: 'Tags of the web pushes whose notifications the user has not seen yet, so a device can close the other ones'

    # Resolved per requested field, so a client that asks for the count alone
    #   does not pay for the tags.
    Payload = Struct.new(:unseen_in_window, :unseen) do
      def unseen_count
        unseen_in_window.count
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

    # The count covers only the notifications the list shows: the user cannot
    #   reach the ones outside its window, so a count of them could not be
    #   cleared. The push tags cover every unseen notification, as a device
    #   closes the pushes whose tags are missing.
    def response
      unseen = OnlineNotification.where(user: context.current_user, seen: false)

      Payload.new(unseen.where(id: online_notification_list(context.current_user).select(:id)), unseen)
    end
  end
end
