# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::DeleteAll < BaseMutation
    description 'Deletes all online notifications for the current user'

    field :success, Boolean, null: false, description: 'Was the deletion successful?'

    def resolve
      Service::OnlineNotification::DeleteAll.with_current_user(context.current_user).execute

      { success: true }
    end
  end
end
