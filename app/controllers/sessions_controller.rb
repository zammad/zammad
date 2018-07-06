# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class SessionsController < ApplicationController
  prepend_before_action :authentication_check, only: %i[switch_to_user list delete]
  skip_before_action :verify_csrf_token, only: %i[create show destroy create_omniauth create_sso]

  # "Create" a login, aka "log the user in"
  def create

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    # authenticate user
    user = User.authenticate(params[:username], params[:password])

    # check maintenance mode
    check_maintenance(user)

    # auth failed
    raise Exceptions::NotAuthorized, 'Wrong Username or Password combination.' if !user

    # remember me - set session cookie to expire later
    expire_after = nil
    if params[:remember_me]
      expire_after = 1.year
    end
    request.env['rack.session.options'][:expire_after] = expire_after

    # set session user
    current_user_set(user)

    # log device
    return if !user_device_log(user, 'session')

    # log new session
    user.activity_stream_log('session started', user.id, true)

    # add session user assets
    assets = {}
    assets = user.assets(assets)

    # auto population of default collections
    collections, assets = SessionHelper.default_collections(user, assets)

    # get models
    models = SessionHelper.models(user)

    # sessions created via this
    # controller are persistent
    session[:persistent] = true

    # return new session data
    render  status: :created,
            json: {
              session: user,
              config: config_frontend,
              models: models,
              collections: collections,
              assets: assets,
            }
  end

  def show

    user_id = nil

    # no valid sessions
    if session[:user_id]
      user_id = session[:user_id]
    end

    if !user_id
      # get models
      models = SessionHelper.models()

      render json: {
        error: 'no valid session',
        config: config_frontend,
        models: models,
        collections: {
          Locale.to_app_model => Locale.where(active: true)
        },
      }
      return
    end

    # Save the user ID in the session so it can be used in
    # subsequent requests
    user = User.find(user_id)

    # log device
    return if !user_device_log(user, 'session')

    # add session user assets
    assets = {}
    assets = user.assets(assets)

    # auto population of default collections
    collections, assets = SessionHelper.default_collections(user, assets)

    # get models
    models = SessionHelper.models(user)

    # return current session
    render json: {
      session: user,
      config: config_frontend,
      models: models,
      collections: collections,
      assets: assets,
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

    # check maintenance mode
    if check_maintenance_only(authorization.user)
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

  def create_sso

    # in case, remove switched_from_user_id
    session[:switched_from_user_id] = nil

    user = User.sso(params)

    # Log the authorizing user in.
    if user

      # check maintenance mode
      if check_maintenance_only(user)
        redirect_to '/#'
        return
      end

      # set current session user
      current_user_set(user)

      # log new session
      user.activity_stream_log('session started', user.id, true)

      # remember last login date
      user.update_last_login
    end

    # redirect to app
    redirect_to '/#'
  end

  # "switch" to user
  def switch_to_user
    permission_check(['admin.session', 'admin.user'])

    # check user
    if !params[:id]
      render(
        json: { message: 'no user given' },
        status: :not_found
      )
      return false
    end

    user = User.find(params[:id])
    if !user
      render(
        json: {},
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
        success: true,
        location: '',
      },
    )
  end

  # "switch" back to user
  def switch_back_to_user

    # check if it's a swich back
    if !session[:switched_from_user_id]
      response_access_deny
      return false
    end

    user = User.lookup(id: session[:switched_from_user_id])
    if !user
      render(
        json: {},
        status: :not_found
      )
      return false
    end

    # rememeber current user
    current_session_user = current_user

    # remove switched_from_user_id
    session[:switched_from_user_id] = nil

    # set old session user again
    current_user_set(user)

    # log end session
    current_session_user.activity_stream_log('ended switch to', user.id, true)

    render(
      json: {
        success: true,
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
      assets: assets,
    }
  end

  def delete
    permission_check('admin.session')
    SessionHelper.destroy(params[:id])
    render json: {}
  end

  private

  def config_frontend

    # config
    config = {}
    Setting.select('name, preferences').where(frontend: true).each do |setting|
      next if setting.preferences[:authentication] == true && !current_user
      value = Setting.get(setting.name)
      next if !current_user && (value == false || value.nil?)
      config[setting.name] = value
    end

    # remember if we can to swich back to user
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
