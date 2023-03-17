# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  # Inherit from this class to define Queries that receive an auto-generated payload type
  #   for the fields they declare, rather than a single explicit type.
  class BaseQueryWithPayload < BaseQuery
    extend GraphQL::Schema::Member::HasFields
    extend GraphQL::Schema::Resolver::HasPayloadType

    description 'Base class for queries that auto-generates a payload object for the declared fields'
  end
end
