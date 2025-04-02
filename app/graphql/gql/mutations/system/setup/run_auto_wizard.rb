# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class System::Setup::RunAutoWizard < BaseMutation
    include Gql::Mutations::Concerns::HandlesAuthentication

    description 'Executes the auto wizard for automated system set-up.'

    argument :token, String, required: false, description: 'Auto wizard access token'

    field :session, Gql::Types::SessionType, description: 'The current session, if the auto wizard was successfully executed.'

    def self.authorize(...)
      true
    end

    def resolve(token: nil)
      user = Service::System::RunAutoWizard.new.execute(token:)

      create_session(user, false, 'password')

      authenticate_result.tap do
        Setting.set('system_init_done', true)
      end
    rescue Service::System::RunAutoWizard::AutoWizardNotEnabledError, Service::System::RunAutoWizard::AutoWizardExecutionError
      error_response({ message: __('An unexpected error occurred during system setup.') })
    end
  end
end
