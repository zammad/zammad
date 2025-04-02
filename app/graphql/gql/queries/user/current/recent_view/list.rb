# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::RecentView::List < BaseQuery

    description 'Fetch tickets recently viewed by the current user'

    argument :limit, Integer, required: false, description: 'Limit for the amount of entries'

    type [Gql::Types::RecentViewType], null: false

    def resolve(limit: 10)
      ::RecentView.list(context.current_user, limit).map do |recent_view|
        ObjectLookup.by_id(recent_view.recent_view_object_id).safe_constantize.lookup(id: recent_view.o_id)
      end
    end
  end
end
