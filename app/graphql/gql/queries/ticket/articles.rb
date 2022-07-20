# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Articles < BaseQuery

    description 'Fetch a ticket by ID'

    argument :ticket, Gql::Types::Input::TicketLocatorInputType, required: true, description: 'Ticket locator'

    type Gql::Types::Ticket::ArticleType.connection_type, null: false

    def resolve(ticket:)
      ::Ticket::Article.where(ticket: ticket).order(:id)
    end
  end
end
