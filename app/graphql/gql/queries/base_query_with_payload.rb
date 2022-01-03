# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  # Inherit from this class to define Queries that receive an auto-generated payload type
  #   for the fields they declare, rather than a single explicit type.
  class BaseQueryWithPayload < BaseQuery
    extend GraphQL::Schema::Member::HasFields
    extend GraphQL::Schema::Resolver::HasPayloadType
  end
end
