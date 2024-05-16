# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationConfigType < Gql::Types::BaseObject
    description 'Settings for ticket notifications.'

    field :matrix, Gql::Types::User::PersonalSettings::NotificationMatrixType
    field :group_ids, [Integer]
  end
end
