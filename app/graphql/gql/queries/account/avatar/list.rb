# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Account::Avatar::List < BaseQuery

    description 'Fetch available avatar list of the currently logged-in user.'

    type [Gql::Types::AvatarType], null: true

    def resolve(...)
      Avatar.list('User', context.current_user.id, raw: true)
    end
  end
end
