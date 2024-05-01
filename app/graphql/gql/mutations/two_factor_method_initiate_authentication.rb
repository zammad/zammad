# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class TwoFactorMethodInitiateAuthentication < BaseMutation
    description 'Fetches the initiation phase data for a two-factor authentication method.'

    argument :login, String, description: 'User name'
    argument :password, String, description: 'Password'
    argument :two_factor_method, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Two-factor authentication method'

    field :initiation_data, GraphQL::Types::JSON, description: ''

    def self.authorize(...)
      true
    end

    def resolve(login:, password:, two_factor_method:)
      initiate(login:, password:, two_factor_method:)
    end

    private

    def initiate(login:, password:, two_factor_method:)
      auth = Auth.new(login, password, only_verify_password: true)

      begin
        auth.valid!
      rescue Auth::Error::Base
        return error_response({ message: __('The username or password is incorrect.') })
      end

      two_factor_method_object = auth.user.auth_two_factor.authentication_method_object(two_factor_method)
      if !two_factor_method_object&.enabled? || !two_factor_method_object&.available?
        return error_response({ message: __('The two-factor authentication method is not enabled.') })
      end

      { initiation_data: two_factor_method_object.initiate_authentication }
    end
  end
end
