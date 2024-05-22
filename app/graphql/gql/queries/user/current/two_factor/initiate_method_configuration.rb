# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TwoFactor::InitiateMethodConfiguration < BaseQuery

    description 'Fetch needed initial configuration data to initiate a authentication method configuration.'

    argument :method_name, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Two factor authentication method'

    type GraphQL::Types::JSON, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(method_name:)
      initiate_authentication_method_configuration = Service::User::TwoFactor::InitiateMethodConfiguration.new(user: context.current_user, method_name: method_name)

      initiate_authentication_method_configuration.execute
    end
  end
end
