# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This is required because of circular references in BaseEdge and BaseConnection.
# Both of them are BaseObject subclasses yet referenced by BaseObject.
# Works fine if BaseObject is loaded first though!
Gql::Types::BaseObject # rubocop:disable Lint/Void

module Gql::Types
  class BaseUnion < GraphQL::Schema::Union
    edge_type_class(Gql::Types::BaseEdge)
    connection_type_class(Gql::Types::BaseConnection)
  end
end
