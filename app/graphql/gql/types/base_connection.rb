# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class BaseConnection < Gql::Types::BaseObject
    # add `nodes` and `pageInfo` fields, as well as `edge_type(...)` and `node_nullable(...)` overrides
    include GraphQL::Types::Relay::ConnectionBehaviors

    node_nullable(false)
    edge_nullable(false)
    edges_nullable(false)
    has_nodes_field(false)

    field :total_count, Integer, null: false, description: 'Indicates the total number of available records.'

    def total_count
      # A connection over a plain Array — a search result that was assembled in Ruby rather than
      #   queried — has no relation to ask about grouping, and Array#size is already the total.
      if object.items.respond_to?(:group_values) && object.items.group_values.any?
        return object.items
          .unscope(:order)
          .count(:all)
          .count
      end

      object.items&.count
    end
  end
end
