# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Login < BaseMutation
    description 'Performs a user login to create a session'

    field :session_id, String, description: 'The current session'

    argument :login, String, required: true, description: 'User name'
    argument :password, String, required: true, description: 'Password'
    argument :fingerprint, String, required: true, description: 'Device fingerprint - a string identifying the device used for the login'

    # reimplementation of `authenticate_with_password`
    def resolve(...)

      # Register user for subsequent auth checks.
      authenticate(...)

      if !context[:current_user]
        return error_response(__('Wrong login or password combination.'))
      end

      { session_id: context[:controller].session.id }
    end

    private

    def authenticate(login:, password:, fingerprint:) # rubocop:disable Metrics/AbcSize
      auth = Auth.new(login, password)
      if !auth.valid?
        return
      end

      user = auth&.user
      context[:controller].session.delete(:switched_from_user_id)

      # Fingerprint param is expected for session logins.
      context[:controller].params[:fingerprint] = fingerprint
      # authentication_check_prerequesits is private
      context[:controller].send(:authentication_check_prerequesits, user, 'session', {})
      context[:current_user] = user
    end
  end
end
