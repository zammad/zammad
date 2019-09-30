# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class SessionsController < ApplicationController
  prepend_before_action :authentication_check, only: %i[switch_to_user list delete]
  skip_before_action :verify_csrf_token, only: %i[show destroy create_omniauth failure_omniauth]
  skip_before_action :user_device_check, only: %i[create_sso]

  # "Create" a login, aka "log the user in"
  def create
    user = authenticate_with_password
    initiate_session_for(user)

    # return new session data
    render status: :created,
           json:   SessionHelper.json_hash(user).merge(config: config_frontend)
  end

  def create_sso
    authenticate_with_sso

    redirect_to '/#'
  end

  def show
    user = authentication_check_only
    raise Exceptions::NotAuthorized, 'no valid session' if user.blank?

    initiate_session_for(user)

    # return current session
    render json: SessionHelper.json_hash(user).merge(config: config_frontend)
  rescue Exceptions::NotAuthorized => e
    render json: {
      error:       e.message,
      config:      config_frontend,
      models:      SessionHelper.models,
      collections: { Locale.to_app_model => Locale.where(active: true) }
    }
  end

  # "Delete" a login, aka "log the user out"
  def destroy

    reset_session

    # Remove the user id from the session
    @_current_user = nil

    # reset session
    request.env['rack.session.options'][:expire_after] = nil

    render json: {}
  end

  def create_omniauth

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    auth = request.env['omniauth.auth']

    if !auth
      logger.info('AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT')

      # redirect to app
      redirect_to '/'
    end

    # Create a new user or add an auth to existing user, depending on
    # whether there is already a user signed in.
    authorization = Authorization.find_from_hash(auth)
    if !authorization
      authorization = Authorization.create_from_hash(auth, current_user)
    end

    if in_maintenance_mode?(authorization.user)
      redirect_to '/#'
      return
    end

    # set current session user
    current_user_set(authorization.user)

    # log new session
    authorization.user.activity_stream_log('session started', authorization.user.id, true)

    # remember last login date
    authorization.user.update_last_login

    # redirect to app
    redirect_to '/'
  end

  def failure_omniauth
    raise Exceptions::UnprocessableEntity, "Message from #{params[:strategy]}: #{params[:message]}"
  end

  # "switch" to user
  def switch_to_user
    permission_check(['admin.session', 'admin.user'])

    # check user
    if !params[:id]
      render(
        json:   { message: 'no user given' },
        status: :not_found
      )
      return false
    end

    user = User.find(params[:id])
    if !user
      render(
        json:   {},
        status: :not_found
      )
      return false
    end

    # remember old user
    session[:switched_from_user_id] = current_user.id

    # log new session
    user.activity_stream_log('switch to', current_user.id, true)

    # set session user
    current_user_set(user)

    render(
      json: {
        success:  true,
        location: '',
      },
    )
  end

  # "switch" back to user
  def switch_back_to_user

    # check if it's a switch back
    raise Exceptions::NotAuthorized if !session[:switched_from_user_id]

    user = User.lookup(id: session[:switched_from_user_id])
    if !user
      render(
        json:   {},
        status: :not_found
      )
      return false
    end

    # remember current user
    current_session_user = current_user

    # remove switched_from_user_id
    session[:switched_from_user_id] = nil

    # set old session user again
    current_user_set(user)

    # log end session
    current_session_user.activity_stream_log('ended switch to', user.id, true)

    render(
      json: {
        success:  true,
        location: '',
      },
    )
  end

  def available
    render json: {
      app_version: AppVersion.get
    }
  end

  def list
    permission_check('admin.session')
    assets = {}
    sessions_clean = []
    SessionHelper.list.each do |session|
      next if session.data['user_id'].blank?

      sessions_clean.push session
      next if session.data['user_id']

      user = User.lookup(id: session.data['user_id'])
      next if !user

      assets = user.assets(assets)
    end
    render json: {
      sessions: sessions_clean,
      assets:   assets,
    }
  end

  def delete
    permission_check('admin.session')
    SessionHelper.destroy(params[:id])
    render json: {}
  end

  private

  def initiate_session_for(user)
    request.env['rack.session.options'][:expire_after] = 1.year if params[:remember_me]
    session[:persistent] = true
    user.activity_stream_log('session started', user.id, true)
  end

  def config_frontend

    # config
    config = {}
    Setting.select('name, preferences').where(frontend: true).each do |setting|
      next if setting.preferences[:authentication] == true && !current_user

      value = Setting.get(setting.name)
      next if !current_user && (value == false || value.nil?)

      config[setting.name] = value
    end

    # remember if we can switch back to user
    if session[:switched_from_user_id]
      config['switch_back_to_possible'] = true
    end

    # remember session_id for websocket logon
    if current_user
      config['session_id'] = session.id
    end

    config
  end

end
