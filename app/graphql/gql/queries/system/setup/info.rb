# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class System::Setup::Info < BaseQuery
    description 'Get current system setup state'

    type Gql::Types::SystemSetupInfoType, null: false

    allow_public_access!

    def resolve
      setup = Service::System::CheckSetup.new
      setup.execute

      {
        status: setup.status,
        type:   setup.type
      }
    end
  end
end
