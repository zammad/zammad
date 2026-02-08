# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Avatar::List < BaseQuery

    description 'Fetch available avatar list of the currently logged-in user.'

    type [Gql::Types::AvatarType], null: true

    requires_permission 'user_preferences.avatar'

    def resolve(...)
      Avatar.list('User', context.current_user.id, raw: true)
    end
  end
end
