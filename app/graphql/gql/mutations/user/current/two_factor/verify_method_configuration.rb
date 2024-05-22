# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::TwoFactor::VerifyMethodConfiguration < BaseMutation
    description 'Verifies two factor authentication method configuration.'

    argument :method_name, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Name of the method which should be verified.'
    argument :payload, GraphQL::Types::JSON, description: 'Payload for the method authentication configuration.'
    argument :configuration, GraphQL::Types::JSON, description: 'Initiated configuration of the authentication method.'

    field :recovery_codes, [String], description: 'One-time two-factor authentication codes'

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.two_factor_authentication')
    end

    def resolve(method_name:, payload:, configuration:)
      verify_method_configuration = Service::User::TwoFactor::VerifyMethodConfiguration.new(
        user:          context.current_user,
        method_name:,
        payload:       payload.is_a?(Hash) ? payload.symbolize_keys! : payload,
        configuration: configuration.symbolize_keys!
      )

      begin
        verify_method_configuration.execute
      rescue Service::User::TwoFactor::VerifyMethodConfiguration::Failed => e
        error_response({ message: e })
      end
    end
  end
end
