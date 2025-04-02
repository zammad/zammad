# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class NotificationMatrixChannelInputType < Gql::Types::BaseInputObject
    description 'Settings for ticket notification channels.'

    argument :email, Boolean, 'Whether to send notifications via email'
    argument :online, Boolean, required: false, default_value: true, description: 'Whether to show notifications via GUI'
  end
end
