# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Add < BaseMutation
    description 'Create a new user access token'

    argument :input, Gql::Types::Input::User::AccessTokenInputType, description: 'The token data'

    field :token_value, String, null: false, description: 'The token itself, shown once' # rubocop:disable Zammad/GraphqlForbidSensitiveFields -- Raw access-token string returned once on creation; the whole point of this mutation.
    field :token, Gql::Types::TokenType, description: 'The token data' # rubocop:disable Zammad/GraphqlForbidSensitiveFields -- Returns TokenType metadata (name/expires_at/last_used_at), not the raw token.

    requires_permission 'user_preferences.access_token'

    def resolve(input:)
      token = Service::User::AccessToken::Create
          .with_current_user(context.current_user)
          .execute(**input)

      {
        token:,
        token_value: token.token
      }
    end
  end
end
