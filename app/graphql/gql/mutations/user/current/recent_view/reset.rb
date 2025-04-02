# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::RecentView::Reset < BaseMutation
    description 'Reset recent view records of the current user'

    field :success, Boolean, null: false, description: 'Was the reset successful?'

    def resolve
      RecentView.where(created_by_id: context.current_user.id).delete_all
      Gql::Subscriptions::User::Current::RecentView::Updates.trigger({}, scope: context.current_user.id)

      { success: true }
    end
  end
end
