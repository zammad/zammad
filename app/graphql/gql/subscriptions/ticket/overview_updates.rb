# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::OverviewUpdates < BaseSubscription

    description 'Updates to overviews'

    argument :ignore_user_conditions, Boolean, description: 'Include additional overviews by ignoring user conditions'

    field :ticket_overviews, [Gql::Types::OverviewType], description: 'Current ticket overviews for the user.'

    def authorized?(ignore_user_conditions:)
      context.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def update(ignore_user_conditions:)
      {
        ticket_overviews: ::Ticket::Overviews.all(current_user: context.current_user, ignore_user_conditions:)
      }
    end
  end
end
