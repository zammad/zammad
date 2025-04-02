# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Channel::Email::InboundMailboxStatsType < Gql::Types::BaseObject
    description 'Inbound mailbox statistics.'

    field :content_messages, Integer, description: 'Number of content emails found during account probing.'
  end
end
