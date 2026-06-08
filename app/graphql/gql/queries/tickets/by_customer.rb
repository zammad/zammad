# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::ByCustomer < BaseQuery
    include Gql::Queries::Tickets::Concerns::TakesTicketStateTypeCategory
    include Gql::Queries::Tickets::Concerns::ReturnsTicketTypeConnectionType

    description 'Fetch tickets of a given customer with optional filters'

    argument :customer_id, GraphQL::Types::ID, description: 'Filter by customer', loads: Gql::Types::UserType
    argument :customer_organizations, Boolean, required: false, description: "Filter by customer's organizations only"

    requires_permission 'ticket.agent'

    def resolve(customer:, customer_organizations: nil, state_type_category: nil)
      scope = ::TicketPolicy::ReadScope.new(context.current_user).resolve.reorder(id: :desc)

      scope = if customer_organizations
                scope.where(organization_id: customer.all_organization_ids)
              else
                scope.where(customer: customer)
              end

      if state_type_category
        scope = scope.where(state_id: ::Ticket::State.by_category(state_type_category).pluck(:id))
      end

      scope
    end
  end
end
