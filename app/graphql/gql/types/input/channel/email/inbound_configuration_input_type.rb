# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class Channel::Email::InboundConfigurationInputType < Gql::Types::BaseInputObject
    description 'Configuration for an inbound email channel.'

    argument :adapter, Gql::Types::Enum::Channel::Email::InboundAdapterType, description: 'Protocol/adapter for this email channel'
    argument :host, String, description: 'Hostname for the email service to connect to'
    argument :port, Integer, description: 'Port for the email service to connect to'
    argument :ssl, Gql::Types::Enum::Channel::Email::SSLType, description: 'Whether to use TLS/SSL'
    argument :user, String, description: 'Username for the email service to connect with'
    argument :password, String, description: 'Password for the email service to connect with'
    argument :ssl_verify, Boolean, required: false, description: 'Whether to perform SSL verification'

    argument :folder, String, required: false, description: 'IMAP Mailbox folder to fetch emails from'
    argument :keep_on_server, Boolean, required: false, description: 'Whether messages should be kept on the IMAP server when fetching'

    argument :archive, Boolean, required: false, description: 'Whether to perform the email import in archive mode'
    argument :archive_before, GraphQL::Types::ISO8601DateTime, required: false, description: 'Import mails older than this date in archive mode'

  end
end
