# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::AccessToken::List < BaseQuery

    description 'Fetch current user access tokens'

    type [Gql::Types::TokenType], null: true

    requires_permission 'user_preferences.access_token'

    def resolve
      Service::User::AccessToken::List
        .new(context.current_user)
        .execute
    end
  end
end
