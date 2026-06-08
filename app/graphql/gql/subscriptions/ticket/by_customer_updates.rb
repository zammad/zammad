# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::ByCustomerUpdates < BaseSubscription
    description 'Updated customer tickets by filter'

    argument :customer_id, GraphQL::Types::ID, description: 'Filter by customer', loads: Gql::Types::UserType

    field :list_changed, Boolean, description: 'Signals that the customer tickets list has changed'

    requires_permission 'ticket.agent'

    def update(customer:)
      { list_changed: true }
    end
  end
end
