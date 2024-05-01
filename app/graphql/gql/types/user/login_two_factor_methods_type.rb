# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class User::LoginTwoFactorMethodsType < Gql::Types::BaseObject

    description 'Two factor authentication methods available for the user about to log-in.'

    field :default_two_factor_authentication_method, Gql::Types::Enum::TwoFactor::AuthenticationMethodType
    field :available_two_factor_authentication_methods, [Gql::Types::Enum::TwoFactor::AuthenticationMethodType], null: false
    field :recovery_codes_available, Boolean, null: false
  end
end
