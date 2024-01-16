# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class User::SignupVerify < BaseMutation
    include Gql::Mutations::Concerns::HandlesAuthentication

    description 'Verify a signed up user.'

    argument :token, String, required: true, description: 'Verification token'

    field :session, Gql::Types::SessionType, description: 'The current session, if the verification was successful.'

    def self.authorize(...)
      true
    end

    def resolve(token:)
      verify = Service::User::SignupVerify.new(token: token)

      begin
        user = verify.execute
      rescue Service::User::SignupVerify::InvalidTokenError => e
        return error_response({ message: e.message })
      end

      create_session(user, false, 'password')

      authenticate_result
    end
  end
end
