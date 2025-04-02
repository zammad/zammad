# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TwoFactor::InitiateMethodConfiguration < BaseQuery
    include Gql::Concerns::HandlesPasswordRevalidationToken

    description 'Fetch needed initial configuration data to initiate a authentication method configuration.'

    argument :method_name, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Two factor authentication method'

    type GraphQL::Types::JSON, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(method_name:, token:)
      verify_token!(token)

      Service::User::TwoFactor::InitiateMethodConfiguration
        .new(user: context.current_user, method_name: method_name)
        .execute
    end
  end
end
