# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class AuthorizationType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    description 'Authorization for an account linked to a user'

    field :provider, String, null: false
    field :uid, String, null: false
    field :username, String
  end
end
