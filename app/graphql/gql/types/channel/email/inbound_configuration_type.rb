# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Channel::Email::InboundConfigurationType < Channel::Email::OutboundConfigurationType
    description 'Configuration for an inbound email channel.'

    field :adapter, Gql::Types::Enum::Channel::Email::InboundAdapterType, null: false, description: 'Protocol/adapter for this email channel'
    field :ssl, Gql::Types::Enum::Channel::Email::SSLType
    field :folder, String, description: 'IMAP Mailbox folder to fetch emails from'
  end
end
