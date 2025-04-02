# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::Authenticates
  extend ActiveSupport::Concern

  private

  def authentication_check(basic_auth_prompt: nil)
    user = authentication_check_only

    # check if basic_auth fallback is possible
    if basic_auth_prompt && !user
      request_http_basic_authentication
      return false
    end

    # return auth not ok
    if !user
      raise Exceptions::Forbidden, __('Authentication required')
    end

    # return auth ok
    true
  end

  def authentication_check_only
    if %w[test development].include?(Rails.env) && ENV['FAKE_SELENIUM_LOGIN_USER_ID'].present? && session[:user_id].blank?
      session[:user_id] = ENV['FAKE_SELENIUM_LOGIN_USER_ID'].to_i
      session[:user_device_updated_at] = Time.zone.now
      session[:authentication_type] = 'password'
    end

    # logger.debug 'authentication_check'
    # logger.debug params.inspect
    # logger.debug session.inspect
    # logger.debug cookies.inspect
    authentication_errors = []

    # already logged in, early exit
    if session.id && session[:user_id]
      logger.debug { 'session based auth check' }
      user = User.lookup(id: session[:user_id])
      return authentication_check_prerequesits(user, 'session') if user

      authentication_errors.push("Can't find User with ID #{session[:user_id]} from Session")
    end

    # check http basic based authentication
    authenticate_with_http_basic do |username, password|
      request.session_options[:skip] = true # do not send a session cookie
      logger.debug { "http basic auth check '#{username}'" }
      if Setting.get('api_password_access') == false
        raise Exceptions::Forbidden, 'API password access disabled!'
      end

      # Disable 2FA for iCal and calendar subscriptions
      only_verify_password = %w[/ical /calendar_subscriptions].any? { |path| request.path.start_with?(path) }
      auth = Auth.new(username, password, only_verify_password:)

      begin
        auth.valid!
        return authentication_check_prerequesits(auth.user, 'basic_auth')
      rescue Auth::Error::AuthenticationFailed
        authentication_errors.push(__('Invalid BasicAuth credentials'))
      rescue Auth::Error::TwoFactorRequired
        authentication_errors.push(__('Two-factor authentication is not supported with HTTP BasicAuth.'))
      end
    end

    # check http token based authentication
    authenticate_with_http_token do |token_string, _options|
      logger.debug { "http token auth check '#{token_string}'" }
      request.session_options[:skip] = true # do not send a session cookie
      if Setting.get('api_token_access') == false
        raise Exceptions::Forbidden, 'API token access disabled!'
      end

      user = Token.check(
        action:        'api',
        token:         token_string,
        inactive_user: true,
      )

      if user
        token = Token.find_by(token: token_string)

        token.last_used_at = Time.zone.now
        token.save!

        raise Exceptions::NotAuthorized, __('Not authorized (token expired)!') if token.expired?

        @_token = token # remember for Pundit authorization / permit!
      end

      @_token_auth = token_string # remember for permission_check
      return authentication_check_prerequesits(user, 'token_auth') if user

      authentication_errors.push(__("Can't find User for Token"))
    end

    # check oauth2 token based authentication
    token = Doorkeeper::OAuth::Token.from_bearer_authorization(request)
    if token
      request.session_options[:skip] = true # do not send a session cookie
      logger.debug { "OAuth2 token auth check '#{token}'" }
      access_token = Doorkeeper::AccessToken.by_token(token)

      raise Exceptions::NotAuthorized, __('The provided token is invalid.') if !access_token

      # check expire
      if access_token.expires_in && (access_token.created_at + access_token.expires_in) < Time.zone.now
        raise Exceptions::NotAuthorized, __('OAuth2 token is expired!')
      end

      # if access_token.scopes.empty?
      #   raise Exceptions::NotAuthorized, 'OAuth2 scope missing for token!'
      # end

      user = User.find(access_token.resource_owner_id)
      return authentication_check_prerequesits(user, 'token_auth') if user

      authentication_errors.push("Can't find User with ID #{access_token.resource_owner_id} for OAuth2 token")
    end

    return false if authentication_errors.blank?

    raise Exceptions::NotAuthorized, authentication_errors.join(', ')
  end

  def authentication_check_prerequesits(user, auth_type)
    raise Exceptions::Forbidden, __('Maintenance mode enabled!') if in_maintenance_mode?(user)

    raise Exceptions::NotAuthorized, Auth::Error::AuthenticationFailed::MESSAGE if !user.active

    current_user_set(user, auth_type)
    user_device_log(user, auth_type)
    logger.debug { "#{auth_type} for '#{user.login}'" }
    user
  end

  def authenticate_and_authorize!
    authentication_check && authorize!
  end
end
