# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::User
  class PersonalSettingsType < Gql::Types::BaseObject
    description 'Personal settings of the current user'

    field :notification_config, Gql::Types::User::PersonalSettings::NotificationConfigType
    field :notification_sound, Gql::Types::User::PersonalSettings::NotificationSoundType
  end
end
