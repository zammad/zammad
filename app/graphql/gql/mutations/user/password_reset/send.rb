# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

# frozen_string_literal: true

module Gql::Mutations
  class User::PasswordReset::Send < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Send password reset link to the user.'

    argument :username, String, required: true, description: 'The user login or email'

    field :success, Boolean, description: 'This indicates if sending of the password reset link was successful.'

    def self.authorize(...)
      true
    end

    def ready?(username:)
      throttle!(limit: 3, period: 1.minute, by_identifier: username)
    end

    def resolve(username:)
      Service::User::PasswordReset::Send
        .new(username: username)
        .execute

      { success: true }
    rescue Exceptions::UnprocessableEntity => e
      error_response({ message: e.message })
    end
  end
end
