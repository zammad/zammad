# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::TaskbarItem::List < BaseQuery

    description 'Fetch available taskbar item list of the currently logged-in user'

    argument :app, Gql::Types::Enum::TaskbarAppType, required: false, description: 'Filter by app'

    type [Gql::Types::User::TaskbarItemType], null: true

    def resolve(app: nil)
      clause = { user_id: context[:current_user].id }
      clause[:app] = app if app

      Taskbar.where(clause).reorder(:prio)
    end
  end
end
