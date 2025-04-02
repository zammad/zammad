# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class CalendarSubscription::SingleOptionsType < Gql::Types::BaseObject
    description 'Options for the single calendar subscription'

    field :own, Boolean
    field :not_assigned, Boolean
  end
end
