# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Subscriptions
  class Ticket::LiveUserUpdates < BaseSubscription
    include Gql::Subscriptions::Concerns::TransformsTaskbarLiveUsers

    description 'Updates to ticket live users (for agents).'

    field :live_users, [Gql::Types::Ticket::LiveUserType], description: 'Current live users from the ticket.'

    requires_permission 'ticket.agent'
  end
end
