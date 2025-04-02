# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Input
  class SystemInformationType < Gql::Types::BaseInputObject
    description 'Basic system information'

    argument :locale_default,   String, 'Default system locale', required: false
    argument :timezone_default, String, 'Default system time zone', required: false
    argument :organization, String, 'System name to display in the app'
    argument :url, String, 'System URL', required: false # optional, because it's not required for system online service
    argument :logo, Gql::Types::BinaryStringType, required: false, description: 'Images to be uploaded.'
  end
end
