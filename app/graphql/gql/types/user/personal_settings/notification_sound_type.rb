# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User::PersonalSettings
  class NotificationSoundType < Gql::Types::BaseObject
    description 'Settings for notification sounds.'

    field :enabled, Boolean, description: 'Whether to play notification sounds'
    field :file, Gql::Types::Enum::NotificationSoundFileType, description: 'Which audio file to play for notification sounds'
  end
end
