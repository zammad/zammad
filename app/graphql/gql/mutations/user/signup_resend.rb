# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::SignupResend < BaseMutation
    include Gql::Concerns::HandlesThrottling

    description 'Resend signup verification email.'

    argument :email, String, required: true, description: 'The user email'

    field :success, Boolean, description: 'This indicates if sending of the token via email was successful.'

    def self.authorize(...)
      true
    end

    def ready?(email:)
      throttle!(limit: 3, period: 1.minute, by_identifier: email)
    end

    def resolve(email:)
      signup = Service::User::Signup.new(user_data: { email: email }, resend: true)

      begin
        signup.execute
      rescue Service::User::Signup::TokenGenerationError
        return error_response({ message: e.message })
      end

      { success: true }
    end
  end
end
