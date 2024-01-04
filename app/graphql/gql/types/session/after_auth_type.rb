# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Session
  class AfterAuthType < Gql::Types::BaseObject
    description 'After-authorization information for front ends'

    field :type, Gql::Types::Enum::AfterAuthTypeType, null: false
    field :data, GraphQL::Types::JSON
  end
end
