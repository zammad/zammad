# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class BaseObject < GraphQL::Schema::Object
    include Gql::Concern::HandlesAuthorization

    edge_type_class       Gql::Types::BaseEdge
    connection_type_class Gql::Types::BaseConnection
    field_class           Gql::Types::BaseField
  end
end
