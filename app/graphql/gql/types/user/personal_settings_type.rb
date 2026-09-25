# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class PersonalSettingsType < Gql::Types::BaseObject
    description 'Personal settings of the current user'

    field :notification_config, Gql::Types::User::PersonalSettings::NotificationConfigType
    field :notification_sound, Gql::Types::User::PersonalSettings::NotificationSoundType
    field :caller_notification_enabled, Boolean, null: false, description: 'Whether the caller notification for incoming calls is enabled'

    # Stored under the `cti` key the old interface reads and writes, where an absent key means off.
    def caller_notification_enabled
      object[:cti] || false
    end
  end
end
