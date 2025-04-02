# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class BaseQuery < GraphQL::Schema::Resolver
    include GraphQL::FragmentCache::ObjectHelpers

    include Gql::Concerns::HandlesAuthorization
    include Gql::Concerns::HasNestedGraphqlName

    description 'Base class for all queries'

    argument_class Gql::Types::BaseArgument

    # Require authentication by default for queries.
    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    def self.register_in_schema(schema)
      schema.field graphql_field_name, resolver: self
    end

  end
end
