# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::RecentClose::List < BaseQuery

    description 'Fetch recently closed objects for the current user'

    argument :limit, Integer, required: false, description: 'Limit for the amount of returned entries'

    type [Gql::Types::RecentCloseType], null: false

    def resolve(limit: 10)
      Service::User::ListRecentCloses
        .with_current_user(context.current_user)
        .execute(limit:)
    end
  end
end
