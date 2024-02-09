# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class SystemImportConfigurationInputType < Gql::Types::BaseInputObject
    description 'Third-party system configuration information'

    argument :url, Gql::Types::UriHttpStringType, 'Third-party system URL', required: true
    argument :username, String, 'Third-party system username', required: false
    argument :secret, String, 'Third-party system password/token', required: false
    argument :source, Gql::Types::Enum::SystemImportSourceType, 'Third-party system source', required: true
    argument :tls_verify, Boolean, 'Verify TLS certificate', required: false
  end
end
