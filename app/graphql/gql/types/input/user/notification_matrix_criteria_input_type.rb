# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class NotificationMatrixCriteriaInputType < Gql::Types::BaseInputObject
    description 'Filter for ticket notification channels.'

    argument :owned_by_me, Boolean, 'Send notifications for my tickets'
    argument :owned_by_nobody, Boolean, 'Send notifications for unassigned tickets'
    argument :subscribed, Boolean, 'Send notifications for my subscribed tickets'
    argument :no, Boolean, 'No filter - send notificationy for any tickets'
  end
end
