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
        Service::System::SetSystemInformation.execute(data: input.to_h)
      rescue Exceptions::InvalidAttribute => e
        return error_response({ message: e.message, field: e.attribute })
      end

      { success: true }
    end
  end
end
