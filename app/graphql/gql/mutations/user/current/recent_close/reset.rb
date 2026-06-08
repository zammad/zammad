# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::RecentClose::Reset < BaseMutation
    description 'Reset recently closed items of the current user'

    field :success, Boolean, null: false, description: 'Was the reset successful?'

    def resolve
      context
        .current_user
        .recent_closes
        .delete_all

      Gql::Subscriptions::User::Current::RecentClose::Updates.trigger({}, scope: context.current_user.id)

      { success: true }
    end
  end
end
