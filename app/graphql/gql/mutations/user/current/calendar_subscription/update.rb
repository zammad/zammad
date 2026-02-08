# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Current::CalendarSubscription::Update < BaseMutation

    description 'Fetch calendar subscriptions settings'

    argument :input, Gql::Types::Input::User::CalendarSubscriptionsConfigInputType, description: 'Settings to set'

    field :success, Boolean, null: false, description: 'Profile appearance settings updated successfully?'

    requires_permission 'user_preferences.calendar+ticket.agent'

    def resolve(input:)
      Service::User::CalendarSubscription::Update
        .new(context.current_user, input: input.to_h)
        .execute

      { success: true }
    end
  end
end
