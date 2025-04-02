# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class AccessTokenInputType < Gql::Types::BaseInputObject
    description 'User access token creation fields'

    argument :name, String, required: true, description: 'The token name'
    argument :permission, [String], required: true, description: 'Permission names'
    argument :expires_at, GraphQL::Types::ISO8601Date, required: false, description: 'The token expiration date'
  end
end
