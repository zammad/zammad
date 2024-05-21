# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class CalendarSubscriptionsConfigType < Gql::Types::BaseObject
    description 'Settings for calendar subscription'

    field :combined_url, Gql::Types::UriHttpStringType

    field :global_options, CalendarSubscription::GlobalOptionsType

    field :new_open,   CalendarSubscription::SingleType
    field :pending,    CalendarSubscription::SingleType
    field :escalation, CalendarSubscription::SingleType
  end
end
