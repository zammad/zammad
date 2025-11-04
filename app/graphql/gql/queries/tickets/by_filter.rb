# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::ByFilter < BaseQuery

    description 'Fetch tickets of a given ticket overview'

    argument :customer_id, GraphQL::Types::ID, required: false, description: 'Filter by customer', loads: Gql::Types::UserType
    argument :state_type_category, Gql::Types::Enum::TicketStateTypeCategoryType, required: false, description: 'Filter by state type category'

    type Gql::Types::TicketType.connection_type, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(state_type_category: nil, customer: nil)
      if customer.nil? && state_type_category.nil?
        raise Exceptions::UnprocessableEntity, __('At least one filter must be provided.')
      end

      scope = ::TicketPolicy::ReadScope.new(context.current_user).resolve.reorder(id: :desc)

      if customer
        scope = scope.where(customer: customer)
      end

      if state_type_category
        scope = scope.where(state_id: ::Ticket::State.by_category(state_type_category).pluck(:id))
      end

      scope
    end
  end
end
