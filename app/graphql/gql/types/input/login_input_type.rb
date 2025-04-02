# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class LoginInputType < Gql::Types::BaseInputObject

    description 'The user login fields.'

    argument :login, String, description: 'User name'
    argument :password, String, description: 'Password'
    argument :two_factor_authentication, Gql::Types::Input::TwoFactor::AuthenticationInputType, required: false, description: 'Two factor authentication'
    argument :two_factor_recovery, Gql::Types::Input::TwoFactor::RecoveryInputType, required: false, description: 'Two factor recovery'
    argument :remember_me, Boolean, required: false, description: 'Remember me - Session expire date will be set to one year'
  end
end
