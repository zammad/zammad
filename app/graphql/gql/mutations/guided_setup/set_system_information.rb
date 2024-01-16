# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class GuidedSetup::SetSystemInformation < BaseMutation

    description 'Sets basic system information'

    argument :input, Gql::Types::Input::SystemInformationType, 'Basic system information'

    field :success, Boolean, null: false, description: 'Did system setup succeed?'

    def self.authorize(_obj, ctx)
      ctx[:current_user].permissions?('admin.wizard')
    end

    def resolve(input:)
      result = Service::System::SetSystemInformation.new.execute(input)

      if !result.success?
        return { success: false, errors: result.errors }
      end

      { success: true }
    end
  end
end
