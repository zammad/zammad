# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input::User
  class NotificationSoundInputType < Gql::Types::BaseInputObject
    description 'Settings for notification sounds.'

    argument :enabled, Boolean, description: 'Whether to play notification sounds'
    argument :file, Gql::Types::Enum::NotificationSoundFileType, description: 'Which audio file to play for notification sounds'
  end
end
