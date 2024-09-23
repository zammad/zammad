# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

# This type counts user or organization tickets accessible to *current user*
# It is very similar to what TicketUserTicketCounterJob does but not the same!
# This counter is used exclusively in New Tech stack
module Gql::Types
  class TicketCountType < Gql::Types::BaseObject
    description 'Open and closed ticket information'

    field :open, Integer, null: false
    field :closed, Integer, null: false

    def open
      ticket_count(:open)
    end

    def closed
      ticket_count(:closed)
    end

    private

    def ticket_count(category)
      TicketPolicy::ReadScope.new(context.current_user)
        .resolve
        .where(
          object_key_column => object.id,
          state_id: ::Ticket::State.by_category(category).select(:id),
        )
        .count
    end

    def object_key_column
      case @object
      when ::Organization
        'organization_id'
      when ::User
        'customer_id'
      else
        raise "Unknown object type #{@object.class}"
      end
    end
  end
end
