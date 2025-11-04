# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# This type counts user or organization tickets accessible to *current user*
# It is very similar to what TicketUserTicketCounterJob does but not the same!
# This counter is used exclusively in New Tech stack
module Gql::Types
  class TicketCountType < Gql::Types::BaseObject
    description 'Open and closed ticket information'

    field :open, Integer, null: false, description: 'Open ticket count of the related object'
    field :open_search_query, String, description: 'Open ticket search query of the related object'
    field :closed, Integer, null: false, description: 'Closed ticket count of the related object'
    field :closed_search_query, String, description: 'Closed ticket search query of the related object'

    def open
      ticket_count(:open)
    end

    def open_search_query
      ticket_search_query(:open)
    end

    def closed
      ticket_count(:closed)
    end

    def closed_search_query
      ticket_search_query(:closed)
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

    def ticket_search_query(category)
      states = ::Ticket::State.by_category(category).pluck(:name)
      return "#{object_key_column}:#{object.id}" if states.empty?

      states_query =
        if states.size > 1
          %( AND state.name:("#{states.map { |state| escape_for_es(state) }.join('" OR "')}"))
        else
          %( AND state.name:"#{escape_for_es(states.first)}")
        end

      "#{object_key_column}:#{object.id}#{states_query}"
    end

    def escape_for_es(string)
      string.gsub(%r{"}) { '\\"' }
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
