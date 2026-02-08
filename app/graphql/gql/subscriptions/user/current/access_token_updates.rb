# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AccessTokenUpdates < BaseSubscription

    description 'Updates to user access tokens'

    subscription_scope :current_user_id

    field :tokens, [Gql::Types::TokenType], null: true, description: 'List of acess tokens for the user'

    requires_permission 'user_preferences.access_token'

    def update
      tokens = Service::User::AccessToken::List
        .new(context.current_user)
        .execute

      { tokens: }
    end
  end
end
