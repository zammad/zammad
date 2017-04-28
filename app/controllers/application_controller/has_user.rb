module ApplicationController::HasUser
  extend ActiveSupport::Concern

  included do
    before_action :set_user, :session_update
  end

  private

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    return @_current_user if @_current_user
    return if !session[:user_id]
    @_current_user = User.lookup(id: session[:user_id])
  end

  def current_user_set(user, auth_type = 'session')
    session[:user_id] = user.id
    @_auth_type = auth_type
    @_current_user = user
    set_user
  end

  # Sets the current user into a named Thread location so that it can be accessed
  # by models and observers
  def set_user
    if !current_user
      UserInfo.current_user_id = 1
      return
    end
    UserInfo.current_user_id = current_user.id
  end

  # update session updated_at
  def session_update
    #sleep 0.6

    session[:ping] = Time.zone.now.iso8601

    # check if remote ip need to be updated
    if session[:user_id]
      if !session[:remote_ip] || session[:remote_ip] != request.remote_ip
        session[:remote_ip] = request.remote_ip
        session[:geo]       = Service::GeoIp.location(request.remote_ip)
      end
    end

    # fill user agent
    return if session[:user_agent]
    session[:user_agent] = request.env['HTTP_USER_AGENT']
  end

  def valid_session_with_user
    return true if current_user
    raise Exceptions::UnprocessableEntity, 'No session user!'
  end
end
