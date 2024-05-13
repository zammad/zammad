# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::AccessToken::List < BaseQuery

    description 'Fetch current user access tokens'

    type [Gql::Types::TokenType], null: true

    def authorized?(...)
      context.current_user.permissions?('user_preferences.access_token')
    end

    def resolve
      Service::User::AccessToken::List
        .new(context.current_user)
        .execute
    end
  end
end
