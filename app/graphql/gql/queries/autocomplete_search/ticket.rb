# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class AutocompleteSearch::Ticket < BaseQuery

    description 'Search for tickets'

    argument :input, Gql::Types::Input::AutocompleteSearch::TicketInputType, required: true, description: 'The input object for the autocomplete search'

    type [Gql::Types::AutocompleteSearch::TicketEntryType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('ticket.agent')
    end

    def resolve(input:)
      # TODO: check if change permission is correct for all usages or if we maybe need a argument from outside for this
      search_tickets(
        query:                     input.query,
        limit:                     input.limit || 10,
        except_ticket_internal_id: input.except_ticket_internal_id
      ).map { |t| coerce_to_result(t) }
    end

    def search_tickets(query:, limit:, except_ticket_internal_id:)
      return search_db(limit: limit, except_ticket_internal_id:) if query.strip.empty?

      search_index(query: query, limit: limit, except_ticket_internal_id:)
    end

    def search_db(limit:, except_ticket_internal_id:)
      TicketPolicy::ChangeScope.new(context.current_user).resolve.where.not(state_id: ignore_state_ids).where.not(id: except_ticket_internal_id).reorder(created_at: :desc).limit(limit)
    end

    def search_index(query:, limit:, except_ticket_internal_id:)
      # We have to filter out the states afterwards, because the search method can only handle either query OR condition.
      ::Ticket.search(
        current_user: context.current_user,
        query:        query,
        scope:        TicketPolicy::ChangeScope,
        limit:        limit,
        sort_by:      'created_at',
        order_by:     'desc',
      ).reject do |ticket|
        ignore_state_ids.include?(ticket.state_id) || except_ticket_internal_id == ticket.id
      end
    end

    def coerce_to_result(ticket)
      {
        value:   Gql::ZammadSchema.id_from_object(ticket),
        label:   "#{ticket_hook}#{ticket.number} - #{ticket.title}",
        heading: ticket.customer.fullname,
        ticket:  ticket,
      }
    end

    private

    def ignore_state_ids
      # TODO: needs this to be more generic?
      ::Ticket::State.where(state_type_id: ::Ticket::StateType.where(name: %w[merged removed]).map(&:id)).map(&:id)
    end

    def ticket_hook
      @ticket_hook ||= Setting.get('ticket_hook')
    end
  end
end
