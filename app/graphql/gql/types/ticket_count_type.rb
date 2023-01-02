# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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
      case @object.class.name
      when 'Organization'
        return 'organization_id'
      when 'User'
        return 'customer_id'
      end

      raise "Unknown object type #{@object.class.name}"
    end
  end
end
