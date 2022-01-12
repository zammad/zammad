# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TicketsByOverview < BaseQuery

    description 'Fetch tickets of a given ticket overview'

    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    argument :overview_id, GraphQL::Types::ID, required: true, description: 'Overview ID'
    argument :order_by, Gql::Types::Enum::TicketOrderByType, required: false, description: 'Set a custom sort by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom sort order'

    type Gql::Types::TicketType.connection_type, null: false

    def resolve(overview_id: nil, order_by: nil, order_direction: nil)
      overview = Gql::ZammadSchema.object_from_id(overview_id, context) || raise("Cannot find overview #{overview_id}")
      # This will fetch tickets with 'overview' permissions, which logically include 'read' permissions.
      Ticket::Overviews.tickets_for_overview(overview, context.current_user, order_by: order_by, order_direction: order_direction)
    end
  end
end
