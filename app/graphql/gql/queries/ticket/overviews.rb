# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class Ticket::Overviews < BaseQuery

    description 'Ticket overviews available in the system'

    argument :ignore_user_conditions, Boolean, description: 'Include additional overviews by ignoring user conditions'
    argument :filter_overview_ids, [GraphQL::Types::ID], required: false, loads: Gql::Types::OverviewType, description: 'Overview IDs to filter for'

    type [Gql::Types::OverviewType], null: false

    def resolve(ignore_user_conditions:, filter_overviews: nil)
      # This effectively scopes the overviews by `:use?` permission.
      scope = ::Ticket::Overviews.all(current_user: context.current_user, ignore_user_conditions:)

      if filter_overviews
        return scope.where(id: filter_overviews.pluck(:id))
      end

      scope
    end
  end
end
