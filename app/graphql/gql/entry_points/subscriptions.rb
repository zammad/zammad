# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::EntryPoints
  class Subscriptions < Gql::Types::BaseObject
    # # Add `node(id: ID!) and `nodes(ids: [ID!]!)`
    # include GraphQL::Types::Relay::HasNodeField
    # include GraphQL::Types::Relay::HasNodesField

    description 'All available subscriptions'

    # No auth required for the main subscription entry point, Gql::Subscriptions perform their own auth handling.
    def self.requires_authentication?
      false
    end

    # Load all available Gql::Subscriptions so that they can be iterated.
    Dir.glob('**/*.rb', base: "#{__dir__}/../subscriptions/").each do |file|
      subclass = file.sub(%r{.rb$}, '').camelize
      subscription = "Gql::Subscriptions::#{subclass}".constantize
      next if subclass.starts_with? 'Base' # Ignore base classes.

      field_name = subclass.gsub('::', '').camelize(:lower).to_sym
      field field_name, subscription: subscription
    end
  end
end
