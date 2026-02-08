# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::Signup < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Sign-up / register user.'

    argument :input, Gql::Types::Input::User::SignupInputType, description: 'The user data'

    field :success, Boolean, description: 'This indicates if creating the user and sending the token was successful.'

    allow_public_access!

    def throttle_if_needed!(input:)
      throttle!(limit: 3, period: 1.minute, by_identifier: input[:email])
    end

    def resolve(input:)
      Service::User::Signup
        .new(user_data: input.to_h)
        .execute

      { success: true }
    rescue PasswordPolicy::Error => e
      error_response({ message: e.message, message_placeholder: e.metadata.drop(1), field: 'password' })
    rescue Exceptions::UnprocessableEntity => e
      error_response({ message: e.message })
    end
  end
end
