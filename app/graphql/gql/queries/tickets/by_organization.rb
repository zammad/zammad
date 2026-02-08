# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::ByOrganization < BaseQuery
    include Gql::Queries::Tickets::Concerns::TakesTicketStateTypeCategory
    include Gql::Queries::Tickets::Concerns::ReturnsTicketTypeConnectionType

    description 'Fetch tickets of a given organization with optional filters'

    argument :organization_id, GraphQL::Types::ID, description: 'Filter by organization', loads: Gql::Types::OrganizationType

    requires_permission 'ticket.agent'

    def resolve(organization:, state_type_category: nil)
      scope = ::TicketPolicy::ReadScope.new(context.current_user).resolve.where(organization:).reorder(id: :desc)

      if state_type_category
        scope = scope.where(state_id: ::Ticket::State.by_category(state_type_category).pluck(:id))
      end

      scope
    end
  end
end
