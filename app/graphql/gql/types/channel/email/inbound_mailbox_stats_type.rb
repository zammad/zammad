# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Channel::Email::InboundMailboxStatsType < Gql::Types::BaseObject
    description 'Inbound mailbox statistics.'

    field :content_messages,   Integer, description: 'Number of content emails found during account probing.'
    field :archive_possible,   Boolean, description: 'Whether an archive import of the email account should be suggested.'
    field :archive_possible_is_fallback, Boolean, description: 'Whether the archive import suggestion is based on a fallback logic due to a missing DATE sort option on the mail server.'
    field :archive_week_range, Integer, description: 'There were emails found older than the specified amount of weeks, therefore an archive import should be suggested.'
  end
end
