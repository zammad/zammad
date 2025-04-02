# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::ValidateConfigurationInbound < Channel::Email::BaseConfiguration
    description 'Validate an inbound email channel configuration by trying to fetch email'

    argument :inbound_configuration, Gql::Types::Input::Channel::Email::InboundConfigurationInputType, 'Configuration to validate'

    field :success, Boolean, description: 'Was the validation successful?'
    field :mailbox_stats, Gql::Types::Channel::Email::InboundMailboxStatsType, description: 'Inbound mailbox data'

    def resolve(inbound_configuration:)
      internal_result = EmailHelper::Probe.inbound(map_type_to_config(inbound_configuration))
      map_probe_result(internal_result, field_prefix: :inbound)
    end
  end
end
