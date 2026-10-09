# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::PushSubscription::Delete < BaseMutation
    description 'Remove a web push subscription of the current user'

    argument :endpoint, String, description: 'Push service endpoint of the subscription to remove'

    field :success, Boolean, null: false, description: 'Was the subscription removed?'

    requires_permission 'user_preferences.notifications+ticket.agent'

    def resolve(endpoint:)
      Service::User::PushSubscription::Delete
        .with_current_user(context.current_user)
        .execute(endpoint:)

      { success: true }
    end
  end
end
