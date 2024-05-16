# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationMatrixType < Gql::Types::BaseObject
    description 'Settings for ticket notifications.'

    field :create, Gql::Types::User::PersonalSettings::NotificationMatrixRowType, 'Notification settings for new tickets'
    field :update, Gql::Types::User::PersonalSettings::NotificationMatrixRowType, 'Notification settings for updated tickets'
    field :reminder_reached, Gql::Types::User::PersonalSettings::NotificationMatrixRowType, 'Notification settings for reached ticket reminders'
    field :escalation, Gql::Types::User::PersonalSettings::NotificationMatrixRowType, 'Notification settings for ticket escalations'
  end
end
