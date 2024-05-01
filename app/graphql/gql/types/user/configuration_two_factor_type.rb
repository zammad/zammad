# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class User::ConfigurationTwoFactorType < Gql::Types::BaseObject

    description 'Two factor configuration information (e.g. configured and default methods) for the user.'

    field :enabled_authentication_methods, [Gql::Types::TwoFactor::EnabledAuthenticationMethodType, { null: false }], null: false, description: 'List of enabled two factor authentication methods (and information about the current user).'
    field :recovery_codes_exist, Boolean, null: false, description: 'Whether recovery codes exist for the current user.'
  end
end
