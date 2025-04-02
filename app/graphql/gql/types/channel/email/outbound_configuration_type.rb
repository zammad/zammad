# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types
  class Channel::Email::OutboundConfigurationType < Gql::Types::BaseObject
    description 'Configuration for an outbound email channel.'

    field :adapter, Gql::Types::Enum::Channel::Email::OutboundAdapterType, null: false, description: 'Protocol/adapter for this email channel'
    field :host, String, description: 'Hostname for the email service to connect to'
    field :port, Integer
    field :user, String, description: 'Username for the email service to connect with'
    field :password, String
    field :ssl_verify, Boolean, description: 'Whether to perform SSL verification'
  end
end
