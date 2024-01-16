# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Setup::Unlock < BaseMutation

    RESOURCE = 'Zammad::System::Setup'.freeze

    argument :value, String, 'Critical section resource value.', required: true

    description 'Unlock critical section, system setup.'

    field :success, Boolean, 'Success.', null: true

    def self.authorize(...)
      true
    end

    def resolve(value:)
      return { success: false } if !Service::ExecuteLockedBlock.locked?(RESOURCE)

      Service::ExecuteLockedBlock.unlock({ resource: RESOURCE, value: })

      { success: true }
    end
  end
end
