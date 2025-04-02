# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AccessTokenUpdates < BaseSubscription

    description 'Updates to user access tokens'

    subscription_scope :current_user_id

    field :tokens, [Gql::Types::TokenType], null: true, description: 'List of acess tokens for the user'

    def authorized?
      context.current_user.permissions?('user_preferences.access_token')
    end

    def update
      tokens = Service::User::AccessToken::List
        .new(context.current_user)
        .execute

      { tokens: }
    end
  end
end
