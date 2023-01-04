# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      object.items&.count
    end
  end
end
