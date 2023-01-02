# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class Login < BaseMutation
    description 'Performs a user login to create a session'

    argument :input, Gql::Types::Input::LoginInputType, 'Login input fields.'

    field :session_id, String, description: 'The current session'

    def self.authorize(...)
      true
    end

    # reimplementation of `authenticate_with_password`
    def resolve(input:)

      # Register user for subsequent auth checks.
      user = authenticate(**input)

      return unified_login_error if !user || !context[:current_user]

      { session_id: context[:controller].session.id }
    end

    private

    def authenticate(login:, password:, fingerprint:, remember_me: false) # rubocop:disable Metrics/AbcSize
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

      initiate_session_for(user, remember_me)

      user
    end

    def initiate_session_for(user, remember_me)
      # TODO: Check if this can be moved to a central place, because it's also the same code in the sessions controller.
      context[:controller].request.env['rack.session.options'][:expire_after] = 1.year if remember_me
      context[:controller].session[:persistent] = true
      user.activity_stream_log('session started', user.id, true)
    end

    def unified_login_error
      error_response({
                       message: __('Login failed. Have you double-checked your credentials and completed the email verification step?')
                     })
    end
  end
end
