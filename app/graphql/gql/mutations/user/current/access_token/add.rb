# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Add < BaseMutation
    description 'Create a new user access token'

    argument :input, Gql::Types::Input::User::AccessTokenInputType, description: 'The token data'

    field :token_value, String, null: false, description: 'The token itself, shown once'
    field :token, Gql::Types::TokenType, description: 'The token data'

    requires_permission 'user_preferences.access_token'

    def resolve(input:)
      token = Service::User::AccessToken::Create
          .new(context.current_user, **input)
          .execute

      {
        token:,
        token_value: token.token
      }
    end
  end
end
