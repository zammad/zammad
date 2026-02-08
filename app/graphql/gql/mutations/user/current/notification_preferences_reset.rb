# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::NotificationPreferencesReset < BaseMutation
    description 'Reset user notification settings'

    field :user, Gql::Types::UserType, null: false, description: 'Updated user object'

    requires_permission 'user_preferences.notifications+ticket.agent'

    def resolve
      ::User.reset_notifications_preferences!(context.current_user)

      { user: context.current_user.reload }
    end
  end
end
