# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Articles < BaseQuery

    description 'Fetch ticket articles by ticket ID'

    argument :ticket_id, ID, loads: Gql::Types::TicketType, description: 'Ticket ID'

    type Gql::Types::Ticket::ArticleType.connection_type, null: false

    def self.register_in_schema(schema)
      schema.field graphql_field_name, resolver: self do
        # The number of articles can be large, but the frontend needs to fetch them all at once.
        # Reduce the calculated complexity to make this possible for the current query.
        complexity lambda { |_ctx, _args, child_complexity|
          (child_complexity / 10).to_i
        }
      end
    end

    def resolve(ticket:)
      Service::Ticket::Article::List
        .with_current_user(context.current_user)
        .execute(ticket:)
    end
  end
end
