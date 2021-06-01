# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module ApplicationController::HasUser
  extend ActiveSupport::Concern

  included do
    before_action :set_user, :session_update
  end

  private

  def current_user
    user_on_behalf = current_user_on_behalf
    return user_on_behalf if user_on_behalf

    current_user_real
  end

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user_real
    return @_current_user if @_current_user
    return if !session[:user_id]

    @_current_user = User.lookup(id: session[:user_id])
  end

  # Finds the user based on the id, login or email which is given
  # in the headers. If it is found then all api activities are done
  # with the behalf of user. With this functionality it is possible
  # to do changes with a user which is different from the admin user.
  # E.g. create a ticket as a customer user based on a user with admin rights.
  def current_user_on_behalf

    # check header
    return if request.headers['X-On-Behalf-Of'].blank?

    # return user if set
    return @_user_on_behalf if @_user_on_behalf

    # get current user
    user_real = current_user_real
    return if !user_real

    # check if the user has admin rights
    raise Exceptions::Forbidden, "Current user has no permission to use 'X-On-Behalf-Of'!" if !user_real.permissions?('admin.user')

    # find user for execution based on the header
    %i[id login email].each do |field|
      search_attributes = search_attributes(field)
      @_user_on_behalf = User.find_by(search_attributes)
      next if !@_user_on_behalf

      return @_user_on_behalf
    end

    # no behalf of user found
    raise Exceptions::Forbidden, "No such user '#{request.headers['X-On-Behalf-Of']}'"
  end

  def search_attributes(field)
    search_attributes = {}
    search_attributes[field] = request.headers['X-On-Behalf-Of']
    if %i[login email].include?(field)
      search_attributes[field] = search_attributes[field].to_s.downcase.strip
    end
    search_attributes
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
      if !session[:remote_ip] || session[:remote_ip] != request.remote_ip # rubocop:disable Style/SoleNestedConditional
        session[:remote_ip] = request.remote_ip
        session[:geo]       = Service::GeoIp.location(request.remote_ip)
      end
    end

    # fill user agent
    return if session[:user_agent]

    session[:user_agent] = request.env['HTTP_USER_AGENT']
  end
end
