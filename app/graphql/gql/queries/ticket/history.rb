# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::History < BaseQuery
    description 'Fetch history of a ticket'

    argument :ticket, Gql::Types::Input::Locator::TicketInputType, description: 'Ticket locator'

    type [Gql::Types::HistoryGroupType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(ticket:)
      Service::History::Group
        .new(current_user: context.current_user)
        .execute(object: ticket)
    end
  end
end
