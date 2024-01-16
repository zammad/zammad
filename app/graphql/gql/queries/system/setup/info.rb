# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Queries
  class System::Setup::Info < BaseQuery
    description 'Get current system setup state'

    type Gql::Types::SystemSetupInfoType, null: false

    # TODO: Create a new base query class for queries that do not require
    # authorization???
    def self.authorize(...)
      true
    end

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
