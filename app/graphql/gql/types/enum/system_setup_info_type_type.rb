# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SystemSetupInfoTypeType < BaseEnum
    description 'Possible system setup types'

    build_string_list_enum Service::System::CheckSetup::TYPES
  end
end
