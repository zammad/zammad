# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::ByOverview < BaseQuery

    description 'Fetch tickets of a given ticket overview'

    argument :overview_id, GraphQL::Types::ID, loads: Gql::Types::OverviewType, description: 'Overview ID'
    argument :order_by, String, required: false, description: 'Set a custom order by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom order direction'

    type Gql::Types::TicketType.connection_type, null: false

    def resolve(overview:, order_by: nil, order_direction: nil)
      # This will fetch tickets with 'overview' permissions, which logically include 'read' permissions.
      ::Ticket::Overviews.tickets_for_overview(overview, context.current_user, order_by: order_by, order_direction: order_direction)
    end
  end
end
