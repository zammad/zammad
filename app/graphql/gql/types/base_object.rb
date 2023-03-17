# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseObject < GraphQL::Schema::Object
    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HasNestedGraphqlName

    edge_type_class       Gql::Types::BaseEdge
    connection_type_class Gql::Types::BaseConnection
    field_class           Gql::Fields::BaseField

    description 'Base class for all GraphQL objects'
  end
end
