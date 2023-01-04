# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class AppMaintenanceTypeType < BaseEnum
    description 'Possible AppVersion messages'

    value AppVersion::MSG_APP_VERSION, 'A new version of the app is available.'
    value AppVersion::MSG_RESTART_MANUAL, 'App needs a restart.'
    value AppVersion::MSG_RESTART_AUTO, 'App is restarting.'
    value AppVersion::MSG_CONFIG_CHANGED, 'The app configuration has changed.'
  end
end
