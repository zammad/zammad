# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Types::Enum
  class SystemSetupInfoStatusType < BaseEnum
    description 'Possible system setup status'

    build_string_list_enum Service::System::CheckSetup::STATES
  end
end
