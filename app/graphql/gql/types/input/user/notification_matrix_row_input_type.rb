# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class NotificationMatrixRowInputType < Gql::Types::BaseInputObject
    description 'Settings for ticket notifications.'

    argument :channel, Gql::Types::Input::User::NotificationMatrixChannelInputType, 'Channels for notification delivery'
    argument :criteria, Gql::Types::Input::User::NotificationMatrixCriteriaInputType, 'Filter for ticket notifications'
  end
end
