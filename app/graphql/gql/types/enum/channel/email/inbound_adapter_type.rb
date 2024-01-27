# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class Channel::Email::InboundAdapterType < BaseEnum
    description 'Inbound email protocols/adapters'

    value 'imap'
    value 'pop3'
  end
end
