# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::RecentByCustomer < BaseQuery

    description 'Fetch recent customer tickets'

    argument :customer_id, GraphQL::Types::ID, description: 'Customer to find tickets for', loads: Gql::Types::UserType
    argument :except_ticket_internal_id, Integer, required: false, description: 'Optional ticket ID to be filtered out from results'
    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::TicketType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(customer:, limit: 6, except_ticket_internal_id: nil)
      open_by_customer(customer:, except_ticket_internal_id:, limit:).all.presence ||
        all_by_customer(customer:, except_ticket_internal_id:, limit:).all
    end

    private

    def open_by_customer(customer:, except_ticket_internal_id:, limit:)
      scope = ::TicketPolicy::ReadScope.new(context.current_user).resolve
        .where(
          customer_id: customer.id,
          state_id:    ::Ticket::State.by_category(:open).select(:id),
        )
        .reorder(created_at: :desc)
        .limit(limit)

      return scope if !except_ticket_internal_id

      scope.where.not(id: except_ticket_internal_id)
    end

    def all_by_customer(customer:, except_ticket_internal_id:, limit:)
      scope = ::TicketPolicy::ReadScope.new(context.current_user).resolve
        .where(customer_id: customer.id)
        .where.not(state_id: ::Ticket::State.by_category_ids(:merged))
        .reorder(created_at: :desc)
        .limit(limit)

      return scope if !except_ticket_internal_id

      scope.where.not(id: except_ticket_internal_id)
    end
  end
end
