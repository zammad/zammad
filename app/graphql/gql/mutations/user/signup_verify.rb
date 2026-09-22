# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::SignupVerify < BaseMutation
    description 'Verify a signed up user.'

    argument :token, String, required: true, description: 'Verification token'

    field :success, Boolean, description: 'This indicates if the verification was successful.'

    allow_public_access!

    def resolve(token:)
      Service::User::SignupVerify.with_current_user(false).execute(token:)

      { success: true }
    rescue Service::User::SignupVerify::InvalidTokenError => e
      error_response({ message: e.message })
    end
  end
end
