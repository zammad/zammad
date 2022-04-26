# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::EntryPoints
  class Queries < Gql::Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    description 'All available queries'

    Mixin::RequiredSubPaths.eager_load_recursive Gql::Queries, "#{__dir__}/../queries/"
    Gql::Queries::BaseQuery.descendants.reject { |klass| klass.name.include?('::Base') }.each do |klass|
      klass.register_in_schema(self)
    end
  end
end
