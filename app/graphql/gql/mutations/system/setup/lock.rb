# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Setup::Lock < BaseMutation

    RESOURCE = 'Zammad::System::Setup'.freeze
    TTL = (60.minutes * 60.seconds * 1000).to_i.freeze

    argument :ttl, Integer, 'Critical section lock life time.', required: false

    description 'Lock critical section, system setup.'

    field :resource, String, 'Critical section resoure name.', null: true
    field :value, String, 'Critical section resoure value.', null: true

    def self.authorize(...)
      true
    end

    def resolve(ttl: TTL)
      Service::System::CheckSetup.new!

      Service::ExecuteLockedBlock.locked!(RESOURCE)
      Service::ExecuteLockedBlock.lock(RESOURCE, ttl)
    end
  end
end
