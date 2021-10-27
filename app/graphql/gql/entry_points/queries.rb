# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Queries < Gql::Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    description 'All available queries'

    # No auth required for the main query entry point, Gql::queries
    #   perform their own auth handling.
    def self.requires_authentication?
      false
    end

    # Load all available Gql::queries so that they can be iterated.
    Mixin::RequiredSubPaths.eager_load_recursive("#{__dir__}/../queries")

    ::Gql::Queries::BaseQuery.descendants.each do |query|
      field_name = query.name.sub('Gql::Queries::', '').gsub('::', '').camelize(:lower).to_sym
      field field_name, resolver: query
    end
  end
end
