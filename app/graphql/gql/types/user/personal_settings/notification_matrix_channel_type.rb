# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationMatrixChannelType < Gql::Types::BaseObject
    description 'Settings for ticket notification channels.'

    field :email, Boolean, 'Whether to send notifications via email'
    field :online, Boolean, 'Whether to show notifications via GUI'
  end
end
