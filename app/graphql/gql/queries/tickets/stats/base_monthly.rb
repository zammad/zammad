# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Tickets::Stats::BaseMonthly < BaseQuery
    description 'Base class for monthly ticket stats queries'

    type [Gql::Types::Ticket::StatsMonthlyType], null: false

    requires_permission 'ticket.agent'

    def resolve_stats(conditions:)
      Service::Ticket::Stats::Monthly.new(current_user: context.current_user).execute(conditions:)
    end
  end
end
