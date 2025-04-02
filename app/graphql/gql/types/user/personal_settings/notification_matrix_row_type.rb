# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationMatrixRowType < Gql::Types::BaseObject
    description 'Settings for ticket notifications.'

    field :channel, Gql::Types::User::PersonalSettings::NotificationMatrixChannelType, 'Channels for notification delivery'
    field :criteria, Gql::Types::User::PersonalSettings::NotificationMatrixCriteriaType, 'Filter for ticket notifications'
  end
end
