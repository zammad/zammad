# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class NotificationMatrixInputType < Gql::Types::BaseInputObject
    description 'Settings for ticket notifications.'

    argument :create, Gql::Types::Input::User::NotificationMatrixRowInputType, 'Notification settings for new tickets'
    argument :update, Gql::Types::Input::User::NotificationMatrixRowInputType, 'Notification settings for updated tickets'
    argument :reminder_reached, Gql::Types::Input::User::NotificationMatrixRowInputType, 'Notification settings for reached ticket reminders'
    argument :escalation, Gql::Types::Input::User::NotificationMatrixRowInputType, 'Notification settings for ticket escalations'
  end
end
