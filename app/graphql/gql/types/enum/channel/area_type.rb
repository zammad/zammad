# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Channel::AreaType < BaseEnum
    description 'The channel area type'

    # Currently fixed list, should be a generic solution with the channel layer in the future.
    CHANNEL_AREAS = [
      'Email::Account',
      'Email::Notification',
      'Facebook::Account',
      'Google::Account',
      'Microsoft365::Account',
      'Sms::Account',
      'Sms::Notification',
      'Telegram::Bot',
      'Twitter::Account',
      'WhatsApp::Business',
    ].freeze

    build_string_list_enum CHANNEL_AREAS
  end
end
