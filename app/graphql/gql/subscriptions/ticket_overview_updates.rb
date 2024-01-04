# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class TicketOverviewUpdates < BaseSubscription

    description 'Updates to overviews'

    field :ticket_overviews, Gql::Types::OverviewType.connection_type, description: 'Current ticket overviews for the user.'

    def authorized?
      context.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def update
      {
        ticket_overviews: ::Ticket::Overviews.all(current_user: context.current_user)
      }
    end
  end
end
