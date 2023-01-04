# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TicketsByOverview < BaseQuery

    description 'Fetch tickets of a given ticket overview'

    argument :overview_id, GraphQL::Types::ID, description: 'Overview ID'
    argument :order_by, String, required: false, description: 'Set a custom order by'
    argument :order_direction, Gql::Types::Enum::OrderDirectionType, required: false, description: 'Set a custom order direction'

    type Gql::Types::TicketType.connection_type, null: false

    def resolve(overview_id: nil, order_by: nil, order_direction: nil)
      overview = Gql::ZammadSchema.authorized_object_from_id(overview_id, type: ::Overview, user: context.current_user)
      # This will fetch tickets with 'overview' permissions, which logically include 'read' permissions.
      ::Ticket::Overviews.tickets_for_overview(overview, context.current_user, order_by: order_by, order_direction: order_direction)
    end
  end
end
