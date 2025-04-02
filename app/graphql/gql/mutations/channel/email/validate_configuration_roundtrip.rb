# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::ValidateConfigurationRoundtrip < Channel::Email::BaseConfiguration
    description 'Validate an email channel configuration first sending and then fetching that same mail'

    argument :inbound_configuration, Gql::Types::Input::Channel::Email::InboundConfigurationInputType, 'Configuration to validate'
    argument :outbound_configuration, Gql::Types::Input::Channel::Email::OutboundConfigurationInputType, 'Configuration to validate'
    argument :email_address, String, description: 'Sender and recipient of verify email'

    field :success, Boolean, null: false, description: 'Was the validation successful?'

    def resolve(inbound_configuration:, outbound_configuration:, email_address:)

      internal_result = EmailHelper::Verify.email(
        inbound:  map_type_to_config(inbound_configuration),
        outbound: map_type_to_config(outbound_configuration),
        sender:   email_address,
      )

      map_probe_result(internal_result, field_prefix: internal_result[:source] || :inbound)
    end
  end
end
