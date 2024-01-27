# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Channel::Email::GuessConfigurationResult < Gql::Types::BaseObject
    description 'Result for channel configuration guessing.'

    field :inbound_configuration,  Gql::Types::Channel::Email::InboundConfigurationType,  description: 'If present, the probing for inbound was successful'
    field :outbound_configuration, Gql::Types::Channel::Email::OutboundConfigurationType, description: 'If present, the probing for inbound was successful'
    field :mailbox_stats, Gql::Types::Channel::Email::InboundMailboxStatsType, description: 'Inbound mailbox data'
  end
end
