# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Checklist < BaseQuery

    description 'Fetch ticket checklist'

    argument :ticket, Gql::Types::Input::Locator::TicketInputType, description: 'Ticket locator'

    type Gql::Types::ChecklistType, null: true

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?(['ticket.agent'])
    end

    def resolve(ticket:)
      ::Checklist.find_by(ticket:)
    end
  end
end
