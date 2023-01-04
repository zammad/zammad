# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Overviews < BaseQuery

    description 'Ticket overviews available in the system'

    type Gql::Types::OverviewType.connection_type, null: false

    def resolve
      # This effectively scopes the overviews by `:use?` permission.
      ::Ticket::Overviews.all(current_user: context.current_user)
    end
  end
end
