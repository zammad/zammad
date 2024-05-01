# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TwoFactor::EnabledAuthenticationMethodType < Gql::Types::BaseObject

    description 'Two factor authentication methods available for the user about to log-in.'

    field :authentication_method, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, null: false
    field :configured, Boolean, null: false
    field :default, Boolean, null: false
  end
end
