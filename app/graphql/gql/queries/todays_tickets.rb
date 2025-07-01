# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class TodaysTickets < BaseQuery
    description 'Fetch all tickets created today'

    type [Gql::Types::TicketType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent', 'ticket.customer'])
    end

    def resolve
      today_start = Time.zone.now.beginning_of_day
      today_end = Time.zone.now.end_of_day

      # Use proper authorization scope
      TicketPolicy::ReadScope.new(context.current_user)
                              .resolve
                              .where(created_at: today_start..today_end)
                              .includes(:state, :priority, :customer, :owner, :group)
                              .reorder(created_at: :desc)
                              .limit(100)
    end
  end
end
