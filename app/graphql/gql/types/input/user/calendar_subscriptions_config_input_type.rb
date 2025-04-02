# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class CalendarSubscriptionsConfigInputType < Gql::Types::BaseInputObject
    description 'Calendar subscriptions options saving'

    argument :alarm,      Boolean, 'Defines if alarm is added'
    argument :new_open,   CalendarSubscription::SingleOptionsInputType, 'Options for New & opened tab'
    argument :pending,    CalendarSubscription::SingleOptionsInputType, 'Options for Pending tab'
    argument :escalation, CalendarSubscription::SingleOptionsInputType, 'Options for Escalation tab'
  end
end
