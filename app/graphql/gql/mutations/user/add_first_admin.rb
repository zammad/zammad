# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::AddFirstAdmin < BaseMutation
    include Gql::Mutations::Concerns::HandlesAuthentication

    description 'Add the first admin user during system set-up and log that user in.'

    argument :input, Gql::Types::Input::User::SignupInputType, description: 'The user data'

    field :session, Gql::Types::SessionType, description: 'The current session, if the user was successfully created.'

    def self.authorize(...)
      true
    end

    def resolve(input:)
      user = Service::User::AddFirstAdmin.new.execute(
        user_data: input.to_h,
        request:   context[:controller].request,
      )
      create_session(user, false, 'password')

      authenticate_result
    rescue Service::System::CheckSetup::SystemSetupError => e
      error_response({ message: e.message })
    rescue PasswordPolicy::Error => e
      error_response({ message: e.message, field: 'password' })
    end
  end
end
