# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class User::Current::CalendarSubscription::List < BaseQuery

    description 'Fetch calendar subscriptions settings'

    type Gql::Types::User::PersonalSettings::CalendarSubscriptionsConfigType, null: false

    def self.authorize(_obj, ctx)
      ctx.current_user.permissions?('user_preferences.calendar+ticket.agent')
    end

    def resolve
      Service::User::CalendarSubscription::TicketPreferencesWithUrls
        .new(context.current_user)
        .execute
    end
  end
end
