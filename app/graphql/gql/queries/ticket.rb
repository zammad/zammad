# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket < BaseQuery

    description 'Fetch a ticket by ID'

    argument :ticket, Gql::Types::Input::TicketLocatorInputType, required: true, description: 'Ticket locator'

    type Gql::Types::TicketType, null: false

    def resolve(ticket:)
      ticket
    end
  end
end
