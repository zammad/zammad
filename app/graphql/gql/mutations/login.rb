# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Login < BaseMutation
    description 'Performs a user login to create a session'

    field :session_id, String, null: false, description: 'The current session'

    argument :login, String, required: true, description: 'User name'
    argument :password, String, required: true, description: 'Password'
    argument :fingerprint, String, required: true, description: 'Device fingerprint - a string identifying the device used for the login'

    # reimplementation of `authenticate_with_password`
    def resolve(...)

      # Register user for subsequent auth checks.
      context[:current_user] = authenticate(...)

      {
        session_id: context[:controller].session.id
      }
    end

    private

    def authenticate(login:, password:, fingerprint:) # rubocop:disable Metrics/AbcSize
      auth = Auth.new(login, password)
      user = auth&.user

      if !auth.valid?
        raise __('Wrong login or password combination.')
      end

      context[:controller].session.delete(:switched_from_user_id)

      # Fingerprint param is expected for session logins.
      context[:controller].params[:fingerprint] = fingerprint
      # authentication_check_prerequesits is private
      context[:controller].send(:authentication_check_prerequesits, user, 'session', {})

      user
    end
  end
end
