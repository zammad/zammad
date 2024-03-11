# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Channel::AreaType < BaseEnum
    description 'The channel area type'

    # Currently fixed list, should be a generic solution with the channel layer in the future.
    build_string_list_enum %w[WhatsApp::Business].freeze
  end
end
