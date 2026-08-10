# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::ByOrganizationUpdates < BaseSubscription
    description 'Updated organization tickets by filter'

    argument :organization_id, GraphQL::Types::ID, description: 'Filter by organization', loads: Gql::Types::OrganizationType

    field :list_changed, Boolean, description: 'Signals that the organization tickets list has changed'

    requires_permission 'ticket.agent'

    def update(organization:)
      tickets = ::Ticket.where(organization_id: organization.id)
      return no_update if tickets.exists? && !::TicketPolicy::ReadScope.new(context.current_user).resolve.merge(tickets).exists?

      { list_changed: true }
    end
  end
end
