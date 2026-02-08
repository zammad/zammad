# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class GuidedSetup::SetSystemInformation < BaseMutation

    description 'Sets basic system information'

    argument :input, Gql::Types::Input::SystemInformationType, 'Basic system information'

    field :success, Boolean, description: 'System setup information updated successfully?'

    requires_permission 'admin.wizard'

    def resolve(input:)
      begin
        # TODO: what are we doing with required string parameter which only holding whitespaces?
        set_system_information = Service::System::SetSystemInformation.new(data: input.to_h)
        set_system_information.execute
      rescue Exceptions::InvalidAttribute => e
        return error_response({ message: e.message, field: e.attribute })
      end

      { success: true }
    end
  end
end
