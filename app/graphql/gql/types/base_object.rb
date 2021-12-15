# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Types
  class BaseObject < GraphQL::Schema::Object
    # Don't include HandlesAuthorization here. The auto-generated payload types
    #   use this as a base but allow no changes of the behaviour regarding autentication/authorization.

    edge_type_class(Gql::Types::BaseEdge)
    connection_type_class(Gql::Types::BaseConnection)
    field_class Gql::Types::BaseField
  end
end
