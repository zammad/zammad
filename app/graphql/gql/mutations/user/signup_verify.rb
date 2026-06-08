# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::SignupVerify < BaseMutation
    include Gql::Mutations::Concerns::HandlesAuthentication

    description 'Verify a signed up user.'

    argument :token, String, required: true, description: 'Verification token'

    field :session, Gql::Types::SessionType, description: 'The current session, if the verification was successful.'

    allow_public_access!

    def resolve(token:)
      user = Service::User::SignupVerify.with_current_user(false).execute(token:)

      create_session(user, false, 'password')

      authenticate_result
    rescue Service::User::SignupVerify::InvalidTokenError => e
      error_response({ message: e.message })
    end
  end
end
