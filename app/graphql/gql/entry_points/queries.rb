# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Queries < Gql::Types::BaseObject
    # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    include GraphQL::Types::Relay::HasNodeField
    include GraphQL::Types::Relay::HasNodesField

    description 'All available queries'

    # No auth required for the main query entry point, Gql::Queries perform their own auth handling.
    def self.requires_authentication?
      false
    end

    # Load all available Gql::Queries so that they can be iterated.
    Dir.glob('**/*.rb', base: "#{__dir__}/../queries/").each do |file|
      subclass = file.sub(%r{.rb$}, '').camelize
      query = "Gql::Queries::#{subclass}".constantize
      next if subclass.starts_with? 'Base' # Ignore base classes.

      field_name = subclass.gsub('::', '').camelize(:lower).to_sym
      field field_name, resolver: query
    end
  end
end
