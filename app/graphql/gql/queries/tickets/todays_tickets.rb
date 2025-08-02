# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::TodaysTickets < BaseQuery

    # Override the auto-generated field name to match frontend expectations
    graphql_name 'TodaysTickets'

    description 'Fetch tickets created today'

    type Gql::Types::TicketType.connection_type, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve
      # Use timezone-aware date filtering to get tickets created today
      tickets = ::Ticket.where(created_at: Time.zone.now.all_day)

      # Apply proper authorization scoping to ensure users only see tickets they have permission to view
      ::TicketPolicy::ReadScope.new(context.current_user, tickets).resolve
    end

    # Force reload trigger
  end
end
