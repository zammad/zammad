class SessionsController < ApplicationController
#  def create
#    render :text => request.env['rack.auth'].inspect
#  end

  # "Create" a login, aka "log the user in"
  def create

    # authenticate user
    user = User.authenticate( params[:username], params[:password] )

    # auth failed
    if !user
      render :json => { :error => 'login failed' }, :status => :unprocessable_entity
      return
    end

    # remember last login date
    user.update_last_login()

    user = User.find_fulldata(user.id)

    # auto population of default collections
    default_collection = SessionHelper::default_collections()
    
    # set session user_id
    session[:user_id] = user['id']

    # check logon session
    logon_session_key = nil
    if params['logon_session']
      logon_session_key = Digest::MD5.hexdigest( rand(999999).to_s + Time.new.to_s )
      session = ActiveRecord::SessionStore::Session.create(
        :session_id => logon_session_key,
        :data => {
          :user_id => user['id']
        }
      )
    end

    # remember me - set session cookie to expire later
    if params[:remember_me]
      request.env['rack.session.options'][:expire_after] = 1.year.from_now
    end

    # return new session data
    render :json => {
      :session             => user,
      :default_collections => default_collection,
      :logon_session       => logon_session_key,
    },
    :status => :created
  end

  def show

    user_id = nil

    # no valid sessions
    if session[:user_id]
      user_id = session[:user_id]
    end

    # check logon session
    if params['logon_session']
      session = ActiveRecord::SessionStore::Session.where( :session_id => params['logon_session'] ).first
      if session
        user_id = session.data[:user_id]
      end
    end

    if !user_id
      render :json => {
        :error  => 'no valid session',
        :config => config_frontend,
      }
      return
    end

    # Save the user ID in the session so it can be used in
    # subsequent requests
    user = User.user_data_full( user_id )

    # auto population of default collections
    default_collection = SessionHelper::default_collections()

    # return current session
    render :json => {
      :session             => user,
      :default_collections => default_collection,
      :config              => config_frontend,
    }
  end

  # "Delete" a login, aka "log the user out"
  def destroy

    # Remove the user id from the session
    @_current_user = session[:user_id] = nil

    # reset session cookie (set :expire_after to '' in case remember_me is active)
    request.env['rack.session.options'][:expire_after] = -1.year.from_now
    request.env['rack.session.options'][:renew] = true

    render :json => { }
  end

  def create_omniauth
    auth = request.env['omniauth.auth']

    if !auth
      logger.info("AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT")

      # redirect to app
      redirect_to '/app'
    end

    # Create a new user or add an auth to existing user, depending on
    # whether there is already a user signed in.
    authorization = Authorization.find_from_hash(auth)
    if !authorization
      authorization = Authorization.create_from_hash(auth, current_user)
    end

    # remember last login date
    authorization.user.update_last_login()

    # Log the authorizing user in.
    session[:user_id] = authorization.user.id

    # redirect to app
    redirect_to '/app'
  end

end