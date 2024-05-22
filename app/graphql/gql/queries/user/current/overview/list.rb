# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::Overview::List < BaseQuery

    description 'Fetch available overviews of the currently logged-in user'

    type [Gql::Types::OverviewType], null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.overview_sorting')
    end

    def resolve
      Service::User::Overview::List
        .new(context.current_user)
        .execute
    end
  end
end
