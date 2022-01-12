# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Overviews < BaseQuery

    description 'Ticket overviews available in the system'

    def self.authorize(_obj, ctx)
      ctx.current_user
    end

    type Gql::Types::OverviewType.connection_type, null: false

    def resolve(...)
      Ticket::Overviews.all(current_user: context.current_user)
    end

  end
end
