# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::MergeTicket < BaseQuery

    description 'Search for tickets'

    argument :input, Gql::Types::Input::AutocompleteSearch::MergeTicketInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::MergeTicketEntryType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(input:)
      search_tickets(query: input.query, limit: input.limit || 10, source_ticket: input.source_ticket).map { |t| coerce_to_result(t) }
    end

    def search_tickets(query:, limit:, source_ticket:)
      if query.strip.empty?
        return search_db(limit: limit, source_ticket: source_ticket)
      end

      search_index(query: query, limit: limit, source_ticket: source_ticket)
    end

    def search_db(limit:, source_ticket:)
      TicketPolicy::ChangeScope.new(context.current_user).resolve.where.not(state_id: ignore_state_ids).where.not(id: source_ticket.id).order(created_at: :desc).limit(limit)
    end

    def search_index(query:, limit:, source_ticket:)
      # We have to filter out the states afterwards, because the search method can only handle either query OR condition.
      ::Ticket.search(
        current_user: context.current_user,
        query:        query,
        scope:        TicketPolicy::ChangeScope,
        limit:        limit,
        sort_by:      'created_at',
        order_by:     'desc',
      ).reject do |ticket|
        ignore_state_ids.include?(ticket.state_id) || source_ticket.id == ticket.id
      end
    end

    def coerce_to_result(ticket)
      {
        value:   Gql::ZammadSchema.id_from_object(ticket),
        label:   ticket.title,
        heading: "##{ticket.number} · #{ticket.customer.fullname}",
        ticket:  ticket,
      }
    end

    private

    def ignore_state_ids
      ::Ticket::State.where(state_type_id: ::Ticket::StateType.where(name: %w[merged removed]).map(&:id)).map(&:id)
    end

  end
end
