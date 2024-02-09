# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Import::Start < BaseMutation
    description 'Start the system import process'

    field :success, Boolean, null: false, description: 'Was the start successful?'

    def self.authorize(...)
      true
    end

    def resolve
      Service::System::Import::Run.new.execute

      { success: true }
    end
  end
end
