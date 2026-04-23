# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class System::Setup::Info < BaseQuery
    description 'Get current system setup state'

    type Gql::Types::SystemSetupInfoType, null: false

    allow_public_access!

    def resolve
      Service::System::CheckSetup.status_info
    end
  end
end
