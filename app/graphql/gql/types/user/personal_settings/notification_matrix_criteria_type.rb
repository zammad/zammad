# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationMatrixCriteriaType < Gql::Types::BaseObject
    description 'Filter for ticket notification channels.'

    field :owned_by_me, Boolean, 'Send notifications for my tickets'
    field :owned_by_nobody, Boolean, 'Send notifications for unassigned tickets'
    field :subscribed, Boolean, 'Send notifications for my subscribed tickets'
    field :no, Boolean, 'No filter - send notificationy for any tickets'
  end
end
