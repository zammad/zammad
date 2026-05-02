# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::PasswordReset::Verify < BaseMutation
    description 'Verify password reset token.'

    argument :token, String, required: true, description: 'Verification token'

    field :success, Boolean, description: 'This indicates if the password reset token is valid.'

    allow_public_access!

    def resolve(token:)
      begin
        Service::User::PasswordReset::Verify.execute(token: token)
      rescue Service::User::PasswordReset::Verify::InvalidTokenError => e
        return error_response({ message: e.message })
      end

      { success: true }
    end
  end
end
