# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class CalendarSubscription::GlobalOptionsType < Gql::Types::BaseObject
    description 'Options applying for all calendar subscriptions'

    field :alarm, Boolean
  end
end
