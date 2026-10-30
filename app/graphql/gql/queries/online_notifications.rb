# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class OnlineNotifications < BaseQuery
    include Gql::Concerns::HandlesOnlineNotificationList

    description 'Online notifications for a given user'

    type Gql::Types::OnlineNotificationType.connection_type, null: false

    def resolve(...)
      online_notification_list(context.current_user)
    end
  end
end
