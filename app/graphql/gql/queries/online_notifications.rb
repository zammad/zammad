# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class OnlineNotifications < BaseQuery

    description 'Online notifications for a given user'

    type Gql::Types::OnlineNotificationType.connection_type, null: false

    def resolve(...)
      OnlineNotification.list(context.current_user, access: 'ignore')
    end
  end
end
