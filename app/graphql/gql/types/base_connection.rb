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
      #   queried — has nothing to count in the database, and Array#size is already the total.
      return object.items.count_rows if object.items.is_a?(ActiveRecord::Relation)

      object.items&.count
    end
  end
end
