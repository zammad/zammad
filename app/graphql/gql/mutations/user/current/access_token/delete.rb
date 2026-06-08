# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Delete < BaseMutation
    description 'Deletes user access token'

    argument :token_id, GraphQL::Types::ID, loads: Gql::Types::TokenType, loads_pundit_method: :destroy?, description: 'The token to be deleted'
    field :success, Boolean, null: false, description: 'Was the access token deletion successful?'

    requires_permission 'user_preferences.access_token'

    def resolve(token:)
      token.destroy!

      { success: true }
    end
  end
end
