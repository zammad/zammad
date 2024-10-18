# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::RecentlyViewed < BaseQuery

    description 'Fetch tickets recently viewed by the current user'

    argument :except_ticket_internal_id, Integer, required: false, description: 'Optional ticket ID to be filtered out from results'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::TicketType], null: false

    # Disable field scoping, as no collection but an array is returned and scoping is performed
    #   right here in the resolver.
    def self.register_in_schema(schema)
      schema.field graphql_field_name, resolver: self, scope: false
    end

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(except_ticket_internal_id: nil, limit: 8)
      ::RecentView.list(context.current_user, limit + 1, 'Ticket').select do |recent_view|
        !except_ticket_internal_id || recent_view.o_id != except_ticket_internal_id
      end.map do |recent_view|
        ::Ticket.lookup(id: recent_view.o_id)
      end.select do |recent_ticket|
        ::TicketPolicy.new(context.current_user, recent_ticket).agent_read_access?
      end.first(limit)
    end
  end
end
