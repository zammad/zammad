# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::EntryPoints
  class Subscriptions < Gql::Types::BaseObject
    # # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    description 'All available subscriptions'

    # Load all available Gql::Subscriptions so that they can be iterated.
    Dir.glob('**/*.rb', base: "#{__dir__}/../subscriptions/").each do |file|
      subclass = file.sub(%r{.rb$}, '').camelize
      next if subclass.starts_with? 'Base' # Ignore base classes.

      "Gql::Subscriptions::#{subclass}".constantize.register_in_schema(self)
    end
  end
end
