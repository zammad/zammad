# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::Cached::ByOverview < BaseQuery
    include Gql::Concerns::HandlesOverviewCaching

    description 'Fetch tickets of a given ticket overview'

    # These arguments (and the ones from pagination such as first:) are part of the cache key.
    argument :overview_id, GraphQL::Types::ID, loads: Gql::Types::OverviewType, description: 'Overview ID'
    argument :order_by, String, required: false, description: 'Set a custom order by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom order direction'
    argument :cache_ttl, Integer do
      description 'How long to cache the overview data, in seconds. This will be part of the cache key so that different durations get different caches.'
    end
    # The following arguments will not be part of the cache key.
    argument :renew_cache, Boolean, required: false, description: 'Force a refresh of the cache content.'
    argument :known_collection_signature, String, required: false do
      description 'Signature of a known collection state on the front end. If there is the same state still on the server, it will not return edges data.'
    end

    type Gql::Types::TicketType.custom_connection_type(type_class: Gql::Types::BaseCachedConnection, type_name: 'CachedTicketConnection'), null: false

    def self.register_in_schema(schema)

      schema.field graphql_field_name, resolver: self do
        # Frontend needs to fetch all visible tickets at once, that can be up to 1000.
        # Reduce the calculated complexity to make this possible for the current query.
        complexity lambda { |_ctx, _args, child_complexity|
          (child_complexity / 10).to_i
        }
      end

    end

    def resolve(cache_ttl:, overview:, renew_cache: false, order_by: nil, order_direction: nil, known_collection_signature: nil)
      if renew_cache
        context.scoped_set!(:renew_cache, true)
      end
      maybe_cached_value(cache_ttl:, overview:, order_by:, order_direction:)
    end

    def maybe_cached_value(cache_ttl:, overview:, order_by:, order_direction:)
      cache_fragment(cache_key: { exclude_arguments: [:renew_cache] }, object_cache_key: object_cache_key(overview), expires_in: cache_ttl) do
        # This will fetch tickets with 'overview' permissions, which logically include 'read' permissions.
        ::Ticket::Overviews.tickets_for_overview(overview, context.current_user, order_by: order_by, order_direction: order_direction)
      end
    end
  end
end
