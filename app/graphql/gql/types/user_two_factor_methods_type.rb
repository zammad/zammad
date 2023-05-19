# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class UserTwoFactorMethodsType < Gql::Types::BaseObject

    description 'Two factor authentication methods available for the user about to log-in.'

    field :default_two_factor_method, Gql::Types::Enum::TwoFactorMethodType
    field :available_two_factor_methods, [Gql::Types::Enum::TwoFactorMethodType], null: false
  end
end
