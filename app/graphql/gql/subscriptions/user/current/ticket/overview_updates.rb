# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class User::Current::Ticket::OverviewUpdates < BaseSubscription

    description 'Updates to overviews according to the sorting of the current user'

    argument :ignore_user_conditions, Boolean, description: 'Include additional overviews by ignoring user conditions'

    field :ticket_overviews, [Gql::Types::OverviewType], description: 'Current ticket overviews for the user.'

    requires_permission 'ticket.agent', 'ticket.customer'

    def update(ignore_user_conditions:)
      {
        ticket_overviews: ::Service::User::Overview::List.with_current_user(context.current_user).execute(ignore_user_conditions:)
      }
    end
  end
end
