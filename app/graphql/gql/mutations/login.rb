# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
      authenticate(**input)

      if !context[:current_user]
        return error_response({
                                message: __('Login failed. Have you double-checked your credentials and completed the email verification step?')
                              })
      end

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

      # TODO: Check if this can be moved to a central place, because it's also the same code in the sessions controller.
      context[:controller].request.env['rack.session.options'][:expire_after] = 1.year if remember_me
      context[:controller].session[:persistent] = true
      user.activity_stream_log('session started', user.id, true)
    end
  end
end
