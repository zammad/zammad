# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Channel::Email::OutboundAdapterType < BaseEnum
    description 'Outbound email protocols/adapters'

    value 'smtp'
    value 'sendmail'
  end
end
