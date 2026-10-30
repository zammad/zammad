# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class OnlineNotification::MarkAllAsSeen < BaseMutation
    description 'Marks all notifications of the current user as seen'

    field :success, Boolean, null: false, description: 'Was the marking successful?'

    def resolve
      Service::OnlineNotification::MarkAllAsSeen.with_current_user(context.current_user).execute

      { success: true }
    end
  end
end
