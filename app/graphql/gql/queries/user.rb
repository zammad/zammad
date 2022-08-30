# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User < BaseQuery
    description 'Fetch a user information by ID'

    argument :user, Gql::Types::Input::UserLocatorInputType, description: 'User locator'

    type Gql::Types::UserType, null: false

    def resolve(user:)
      user
    end
  end
end
