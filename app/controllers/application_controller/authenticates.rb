module ApplicationController::Authenticates
  extend ActiveSupport::Concern

  included do
    skip_before_action :verify_authenticity_token
  end

  private

  def response_access_deny
    raise Exceptions::NotAuthorized
  end

  def permission_check(key)
    if @_token_auth
      user = Token.check(
        action: 'api',
        name: @_token_auth,
        permission: key,
      )
      return false if user
      raise Exceptions::NotAuthorized, 'Not authorized (token)!'
    end

    return false if current_user && current_user.permissions?(key)
    raise Exceptions::NotAuthorized, 'Not authorized (user)!'
  end

  def authentication_check(auth_param = {})
    user = authentication_check_only(auth_param)

    # check if basic_auth fallback is possible
    if auth_param[:basic_auth_promt] && !user
      return request_http_basic_authentication
    end

    # return auth not ok
    if !user
      raise Exceptions::NotAuthorized, 'authentication failed'
    end

    # return auth ok
    true
  end

  def authentication_check_only(auth_param = {})
    #logger.debug 'authentication_check'
    #logger.debug params.inspect
    #logger.debug session.inspect
    #logger.debug cookies.inspect

    # already logged in, early exit
    if session.id && session[:user_id]
      logger.debug 'session based auth check'
      user = User.lookup(id: session[:user_id])
      return authentication_check_prerequesits(user, 'session', auth_param) if user
    end

    # check sso based authentication
    sso_user = User.sso(params)
    if sso_user
      if authentication_check_prerequesits(sso_user, 'session', auth_param)
        session[:persistent] = true
        return sso_user
      end
    end

    # check http basic based authentication
    authenticate_with_http_basic do |username, password|
      request.session_options[:skip] = true # do not send a session cookie
      logger.debug "http basic auth check '#{username}'"
      if Setting.get('api_password_access') == false
        raise Exceptions::NotAuthorized, 'API password access disabled!'
      end
      user = User.authenticate(username, password)
      return authentication_check_prerequesits(user, 'basic_auth', auth_param) if user
    end

    # check http token based authentication
    authenticate_with_http_token do |token_string, _options|
      logger.debug "http token auth check '#{token_string}'"
      request.session_options[:skip] = true # do not send a session cookie
      if Setting.get('api_token_access') == false
        raise Exceptions::NotAuthorized, 'API token access disabled!'
      end
      user = Token.check(
        action: 'api',
        name: token_string,
        inactive_user: true,
      )
      if user && auth_param[:permission]
        user = Token.check(
          action: 'api',
          name: token_string,
          permission: auth_param[:permission],
          inactive_user: true,
        )
        raise Exceptions::NotAuthorized, 'Not authorized (token)!' if !user
      end

      if user
        token = Token.find_by(name: token_string)

        token.last_used_at = Time.zone.now
        token.save!

        if token.expires_at &&
           Time.zone.today >= token.expires_at
          raise Exceptions::NotAuthorized, 'Not authorized (token expired)!'
        end
      end

      @_token_auth = token_string # remember for permission_check
      return authentication_check_prerequesits(user, 'token_auth', auth_param) if user
    end

    # check oauth2 token based authentication
    token = Doorkeeper::OAuth::Token.from_bearer_authorization(request)
    if token
      request.session_options[:skip] = true # do not send a session cookie
      logger.debug "oauth2 token auth check '#{token}'"
      access_token = Doorkeeper::AccessToken.by_token(token)

      if !access_token
        raise Exceptions::NotAuthorized, 'Invalid token!'
      end

      # check expire
      if access_token.expires_in && (access_token.created_at + access_token.expires_in) < Time.zone.now
        raise Exceptions::NotAuthorized, 'OAuth2 token is expired!'
      end

      # if access_token.scopes.empty?
      #   raise Exceptions::NotAuthorized, 'OAuth2 scope missing for token!'
      # end

      user = User.find(access_token.resource_owner_id)
      return authentication_check_prerequesits(user, 'token_auth', auth_param) if user
    end

    false
  end

  def authentication_check_prerequesits(user, auth_type, auth_param)
    if check_maintenance_only(user)
      raise Exceptions::NotAuthorized, 'Maintenance mode enabled!'
    end

    if user.active == false
      raise Exceptions::NotAuthorized, 'User is inactive!'
    end

    # check scopes / permission check
    if auth_param[:permission] && !user.permissions?(auth_param[:permission])
      raise Exceptions::NotAuthorized, 'Not authorized (user)!'
    end

    current_user_set(user, auth_type)
    user_device_log(user, auth_type)
    logger.debug "#{auth_type} for '#{user.login}'"
    true
  end
end
