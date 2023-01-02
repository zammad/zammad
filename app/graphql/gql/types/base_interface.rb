# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  module BaseInterface
    include GraphQL::Schema::Interface

    edge_type_class       Gql::Types::BaseEdge
    connection_type_class Gql::Types::BaseConnection
    field_class           Gql::Fields::BaseField

    description 'Base class for all interfaces'
  end
end
