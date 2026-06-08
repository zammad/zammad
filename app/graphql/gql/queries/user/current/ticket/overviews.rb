# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Ticket::Overviews < BaseQuery

    description 'Ticket overviews according to the personal sorting of the current user'

    argument :ignore_user_conditions, Boolean, description: 'Include additional overviews by ignoring user conditions'

    type [Gql::Types::OverviewType], null: false

    def resolve(ignore_user_conditions:)
      Service::User::Overview::List.with_current_user(context.current_user).execute(ignore_user_conditions:)
    end
  end
end
