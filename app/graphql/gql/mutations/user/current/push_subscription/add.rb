# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::PushSubscription::Add < BaseMutation
    description 'Register the web push subscription of the current browser for the current user'

    argument :input, Gql::Types::Input::User::PushSubscriptionInputType, description: 'The push subscription data'

    field :success, Boolean, description: 'Was the subscription registered?'

    requires_permission 'user_preferences.notifications+ticket.agent'

    def resolve(input:)
      Service::User::PushSubscription::Add
        .with_current_user(context.current_user)
        .execute(**input.to_h)

      { success: true }
    end
  end
end
