# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Channel::Email::OutboundConfigurationInputType < Gql::Types::BaseInputObject
    description 'Configuration for an outbound email channel.'

    argument :adapter, Gql::Types::Enum::Channel::Email::OutboundAdapterType, description: 'Protocol/adapter for this email channel'
    argument :host, String, required: false, description: 'Hostname for the email service to connect to'
    argument :port, Integer, required: false, description: 'Port for the email service to connect to'
    argument :user, String, required: false, description: 'Username for the email service to connect with'
    argument :password, String, required: false, description: 'Password for the email service to connect with'
    argument :ssl_verify, Boolean, required: false, description: 'Whether to perform SSL verification'
  end
end
