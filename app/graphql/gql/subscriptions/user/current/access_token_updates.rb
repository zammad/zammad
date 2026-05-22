# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::AccessTokenUpdates < BaseSubscription

    description 'Updates to user access tokens'

    subscription_scope :current_user_id

    field :tokens, [Gql::Types::TokenType], null: true, description: 'List of access tokens for the user' # rubocop:disable Zammad/GraphqlForbidSensitiveFields -- Returning the user's own access token metadata is the purpose of this subscription.

    requires_permission 'user_preferences.access_token'

    def update
      tokens = Service::User::AccessToken::List
        .with_current_user(context.current_user)
        .execute

      { tokens: }
    end
  end
end
