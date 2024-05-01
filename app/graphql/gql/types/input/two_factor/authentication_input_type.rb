# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::TwoFactor
  class AuthenticationInputType < Gql::Types::BaseInputObject
    description 'Payload for the two factor authentication'

    argument :two_factor_method, Gql::Types::Enum::TwoFactor::AuthenticationMethodType, description: 'Two factor authentication method'
    argument :two_factor_payload, GraphQL::Types::JSON, description: 'Two factor authentication token'

  end
end
