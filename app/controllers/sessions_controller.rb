# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

class SessionsController < ApplicationController

  # "Create" a login, aka "log the user in"
  def create

    # authenticate user
    user = User.authenticate( params[:username], params[:password] )

    # auth failed
    if !user
      render :json => { :error => 'login failed' }, :status => :unauthorized
      return
    end

    # remember me - set session cookie to expire later
    if params[:remember_me]
      request.env['rack.session.options'][:expire_after] = 1.year
    else
      request.env['rack.session.options'][:expire_after] = nil
    end
    # both not needed to set :expire_after works fine
    #  request.env['rack.session.options'][:renew] = true
    #  reset_session

    # set session user
    current_user_set(user)

    # log new session
    user.activity_stream_log( 'session started', user.id, true )

    # auto population of default collections
    default_collection = SessionHelper::default_collections(user)

    # set session user_id
    user = User.find_fulldata(user.id)

    # check logon session
    logon_session_key = nil
    if params['logon_session']
      logon_session_key = Digest::MD5.hexdigest( rand(999999).to_s + Time.new.to_s )
#      session = ActiveRecord::SessionStore::Session.create(
#        :session_id => logon_session_key,
#        :data => {
#          :user_id => user['id']
#        }
#      )
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
    default_collection = SessionHelper::default_collections( User.find(user_id) )

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

    # reset session cookie (reset :expire_after in case remember_me is active)
    request.env['rack.session.options'][:expire_after] = -1.year
    request.env['rack.session.options'][:renew] = true

    render :json => { }
  end

  def create_omniauth
    auth = request.env['omniauth.auth']

    if !auth
      logger.info("AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT")

      # redirect to app
      redirect_to '/'
    end

    # Create a new user or add an auth to existing user, depending on
    # whether there is already a user signed in.
    authorization = Authorization.find_from_hash(auth)
    if !authorization
      authorization = Authorization.create_from_hash(auth, current_user)
    end

    # set current session user
    current_user_set(authorization.user)

    # log new session
    user.activity_stream_log( 'session started', authorization.user.id, true )

    # remember last login date
    authorization.user.update_last_login

    # redirect to app
    redirect_to '/'
  end

  def create_sso
    user = User.sso(params)

    # Log the authorizing user in.
    if user

      # set current session user
      current_user_set(user)

      # log new session
      user.activity_stream_log( 'session started', user.id, true )

      # remember last login date
      user.update_last_login
    end

    # redirect to app
    redirect_to '/#'
  end

  # "switch" to user
  def switch_to_user
    return if deny_if_not_role('Admin')

    # check user
    if !params[:id]
      render(
        :json   => { :message => 'no user given' },
        :status => :not_found
      )
      return false
    end

    user = User.lookup( :id => params[:id] )
    if !user
      render(
        :json   => {},
        :status => :not_found
      )
      return false
    end

    # log new session
    user.activity_stream_log( 'switch to', current_user.id, true )

    # set session user
    current_user_set(user)

    redirect_to '/#'
  end

  def list
    return if deny_if_not_role('Admin')
    sessions = ActiveRecord::SessionStore::Session.order('updated_at DESC').limit(10000)
    assets = {}
    sessions_clean = []
    sessions.each {|session|
      next if !session.data['user_id']
      sessions_clean.push session
      if session.data['user_id']
        user = User.lookup( :id => session.data['user_id'] )
        assets = user.assets( assets )
      end
    }
    render :json => {
      :sessions => sessions_clean,
      :assets   => assets,
    }
  end

  def delete_old
    ActiveRecord::SessionStore::Session.where('request_type = ? AND updated_at < ?', 1, Time.now - 90.days ).delete_all
    ActiveRecord::SessionStore::Session.where('request_type = ? AND updated_at < ?', 2, Time.now - 2.days ).delete_all
    render :json => {}
  end

  def delete
    return if deny_if_not_role('Admin')
    session = ActiveRecord::SessionStore::Session.where( :id => params[:id] ).first
    if session
      session.destroy
    end
    render :json => {}
  end
end
