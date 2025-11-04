# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User < BaseQuery
    description 'Fetch a user information by ID'

    argument :user_id, ID, loads: Gql::Types::UserType, description: 'User ID'

    type Gql::Types::UserType, null: false

    def resolve(user:)
      user
    end
  end
end
