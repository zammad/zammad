# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TwoFactor::InitiateMethodConfiguration < BaseQuery
    include Gql::Concerns::HandlesPasswordRevalidationToken

    description 'Fetch needed initial configuration data to initiate a authentication method configuration.'

    argument :method_name, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Two factor authentication method'

    type GraphQL::Types::JSON, null: false

    requires_permission 'user_preferences.two_factor_authentication'

    def resolve(method_name:, token:)
      verify_token!(token)

      Service::User::TwoFactor::InitiateMethodConfiguration
        .new(user: context.current_user, method_name: method_name)
        .execute
    end
  end
end
