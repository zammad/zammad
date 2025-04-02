# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Articles < BaseQuery

    description 'Fetch ticket articles by ticket ID'

    argument :ticket, Gql::Types::Input::Locator::TicketInputType, description: 'Ticket locator'

    type Gql::Types::Ticket::ArticleType.connection_type, null: false

    def resolve(ticket:)
      Service::Ticket::Article::List
        .new(current_user: context.current_user)
        .execute(ticket:)
    end
  end
end
