# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::AccessToken::Delete < BaseMutation
    description 'Deletes user access token'

    argument :token_id, GraphQL::Types::ID, loads: Gql::Types::TokenType, description: 'The token o be deleted'
    field :success, Boolean, null: false, description: 'Was the access token deletion successful?'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.access_token')
    end

    def resolve(token:)
      token.destroy!

      { success: true }
    end

    def authorized?(token:)
      Pundit.authorize(context.current_user, token, :destroy?)
    end
  end
end
