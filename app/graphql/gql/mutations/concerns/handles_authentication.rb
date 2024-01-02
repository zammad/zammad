# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations::Concerns::HandlesAuthentication
  extend ActiveSupport::Concern

  included do # rubocop:disable Metrics/BlockLength

    # reimplementation of `authenticate_with_password`
    def authenticate(login:, password:, two_factor_authentication: nil, two_factor_recovery: nil, remember_me: false)
      auth = begin
        if two_factor_authentication.present?
          Auth.new(login, password, **two_factor_authentication)
        elsif two_factor_recovery.present?
          Auth.new(login, password, two_factor_method: 'recovery_codes', two_factor_payload: two_factor_recovery[:recovery_code])
        else
          Auth.new(login, password)
        end
      end

      begin
        auth.valid!
      rescue Auth::Error::TwoFactorRequired => e
        return {
          two_factor_required: {
            default_two_factor_authentication_method:    e.default_two_factor_authentication_method,
            available_two_factor_authentication_methods: e.available_two_factor_authentication_methods,
            recovery_codes_available:                    e.recovery_codes_available
          }
        }
      rescue Auth::Error::Base => e
        return error_response({ message: e.message })
      end

      create_session(auth&.user, remember_me)

      authenticate_result
    end

    def authenticate_result
      {
        session: {
          id:         context[:controller].session.id,
          after_auth: Auth::AfterAuth.run(context.current_user, context[:controller].session)
        }
      }
    end

    def create_session(user, remember_me, authentication_type = 'password')
      context[:controller].session.delete(:switched_from_user_id)

      # authentication_check_prerequesits is private
      context[:controller].send(:authentication_check_prerequesits, user, 'session')
      context[:current_user] = user

      initiate_session_for(user, remember_me, authentication_type)
    end

    def initiate_session_for(user, remember_me, authentication_type)
      # TODO: Check if this can be moved to a central place, because it's also the same code in the sessions controller.
      context[:controller].request.env['rack.session.options'][:expire_after] = 1.year if remember_me
      initiate_session_data(authentication_type)
      user.activity_stream_log('session started', user.id, true)
    end

    def initiate_session_data(authentication_type)
      context[:controller].session[:persistent] = true
      context[:controller].session[:authentication_type] = authentication_type
    end
  end
end
