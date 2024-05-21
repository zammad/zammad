# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class CalendarSubscription::SingleType < Gql::Types::BaseObject
    description 'Settings for the single calendar subscription'

    field :url, Gql::Types::UriHttpStringType
    field :options, Gql::Types::User::PersonalSettings::CalendarSubscription::SingleOptionsType
  end
end
