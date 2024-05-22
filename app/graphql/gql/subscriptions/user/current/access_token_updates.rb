# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AccessTokenUpdates < BaseSubscription

    argument :user_id, GraphQL::Types::ID, 'ID of the user to receive access token updates for', loads: Gql::Types::UserType

    description 'Updates to given user access tokens'

    field :tokens, [Gql::Types::TokenType], null: true, description: 'List of acess tokens for the user'

    # Instance method: allow subscriptions only for the current user
    def authorized?(user:)
      context.current_user.permissions?('user_preferences.access_token') && user.id == context.current_user.id
    end

    def update(user:)
      tokens = Service::User::AccessToken::List
        .new(user)
        .execute

      { tokens: }
    end
  end
end
