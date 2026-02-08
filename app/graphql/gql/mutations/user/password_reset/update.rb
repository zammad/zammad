# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

module Gql::Mutations
  class User::PasswordReset::Update < BaseMutation
    description 'Update user password via reset token.'

    argument :token, String, required: true, description: 'Verification token'
    argument :password, String, required: true, description: 'The user password'

    field :success, Boolean, description: 'This indicates if the password update was successful.'

    allow_public_access!

    def resolve(token:, password:)
      update = Service::User::PasswordReset::Update.new(token: token, password: password)

      begin
        update.execute
      rescue Service::User::PasswordReset::Update::InvalidTokenError, Service::User::PasswordReset::Update::EmailError => e
        return error_response({ message: e.message })
      rescue PasswordPolicy::Error => e
        return error_response({ message: e.message, message_placeholder: e.metadata.drop(1), field: 'password' })
      end

      { success: true }
    end
  end
end
