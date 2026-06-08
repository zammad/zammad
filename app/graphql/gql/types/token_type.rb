# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class TokenType < Gql::Types::BaseObject
    include Gql::Types::Concerns::IsModelObject

    # TokenPolicy has no show?, so we can't use HasPunditPolicy here.

    description 'User access token'

    belongs_to :user, Gql::Types::UserType

    field :name, String
    field :preferences, GraphQL::Types::JSON
    field :expires_at, GraphQL::Types::ISO8601DateTime
    field :last_used_at, GraphQL::Types::ISO8601DateTime
  end
end
