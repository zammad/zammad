# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::CalendarSubscription::List < BaseQuery

    description 'Fetch calendar subscriptions settings'

    type Gql::Types::User::PersonalSettings::CalendarSubscriptionsConfigType, null: false

    requires_permission 'user_preferences.calendar+ticket.agent'

    def resolve
      Service::User::CalendarSubscription::TicketPreferencesWithUrls
        .new(context.current_user)
        .execute
    end
  end
end
