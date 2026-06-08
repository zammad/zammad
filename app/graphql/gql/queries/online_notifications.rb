# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class OnlineNotifications < BaseQuery

    description 'Online notifications for a given user'

    type Gql::Types::OnlineNotificationType.connection_type, null: false

    def resolve(...)
      OnlineNotification
        .list(
          context.current_user,
          access: 'ignore'
        )
        .where(
          # Make sure to limit it to known meta object types.
          object_lookup_id: ObjectLookup.where(
            name: Gql::Types::ActivityMessageMetaObjectType.possible_types.map { |t| t.name.delete_prefix('Gql::Types::').delete_suffix('Type') }
          ).select(:id)
        )
    end
  end
end
