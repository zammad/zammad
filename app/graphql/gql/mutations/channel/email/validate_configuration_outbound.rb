# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::ValidateConfigurationOutbound < Channel::Email::BaseConfiguration
    description 'Validate an outbound email channel configuration by sending a test email'

    argument :outbound_configuration, Gql::Types::Input::Channel::Email::OutboundConfigurationInputType, description: 'Configuration to validate'
    argument :email_address, String, description: 'Sender and recipient of verify email'

    field :success, Boolean, null: false, description: 'Was the validation successful?'

    def resolve(outbound_configuration:, email_address:)
      internal_result = EmailHelper::Probe.outbound(map_type_to_config(outbound_configuration), email_address)
      map_probe_result(internal_result, field_prefix: :outbound)
    end
  end
end
