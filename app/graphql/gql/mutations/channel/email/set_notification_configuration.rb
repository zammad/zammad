# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Channel::Email::SetNotificationConfiguration < Channel::Email::BaseConfiguration
    description 'Set confioguration for sending system notification emails'

    argument :outbound_configuration, Gql::Types::Input::Channel::Email::OutboundConfigurationInputType, description: 'Configuration to validate'

    field :success, Boolean, description: 'Was the operation successful?'

    def ready?(...)
      raise Exceptions::Forbidden if Setting.get('system_online_service')

      true
    end

    def resolve(outbound_configuration:)
      Service::System::SetEmailNotificationConfiguration
        .new(
          adapter:           outbound_configuration.adapter,
          new_configuration: outbound_configuration.to_h.except(:adapter)
        ).execute

      { success: true }
    end
  end
end
