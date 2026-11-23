# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::SetNotificationConfiguration < Channel::Email::BaseConfiguration
    description 'Check the configuration for sending system notification emails with a test email and save it'

    argument :outbound_configuration, Gql::Types::Input::Channel::Email::OutboundConfigurationInputType, description: 'Configuration to check and save'
    argument :test_address, String, required: false, description: 'Recipient of the test email for a mail server which only delivers to internal recipients'

    field :success, Boolean, description: 'Was the operation successful?'
    field :refused, Boolean, description: 'Did the mail server refuse the test email of the usual check? A check with a test address may follow.'

    requires_disabled_setting 'system_online_service'

    def resolve(outbound_configuration:, test_address: nil)
      result = Service::System::CheckAndSetEmailNotificationConfiguration
        .execute(
          adapter:           outbound_configuration.adapter,
          new_configuration: outbound_configuration.to_h.except(:adapter),
          test_address:,
        )

      map_probe_result(result, field_prefix: :outbound).merge(refused: result[:refused] == true)
    end
  end
end
