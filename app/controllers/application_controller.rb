class ApplicationController < ActionController::Base
  include UserInfo
#  http_basic_authenticate_with :name => "test", :password => "ttt"

  helper_method :current_user, :authentication_check, :config_frontend, :user_data_full

  before_filter :set_user
  before_filter :cors_preflight_check

  after_filter  :set_access_control_headers
  after_filter  :trigger_events

  # For all responses in this controller, return the CORS access control headers.
  def set_access_control_headers 
    headers['Access-Control-Allow-Origin']      = '*'
    headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
    headers['Access-Control-Max-Age']           = '1728000'
    headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'
    headers['Access-Control-Allow-Credentials'] = 'true'
  end
   
  # If this is a preflight OPTIONS request, then short-circuit the
  # request, return only the necessary headers and return an empty
  # text/plain.
  
  def cors_preflight_check
    if request.method == 'OPTIONS'
      headers['Access-Control-Allow-Origin']      = '*'
      headers['Access-Control-Allow-Methods']     = 'POST, GET, PUT, DELETE, OPTIONS'
      headers['Access-Control-Allow-Headers']     = 'Content-Type, Depth, User-Agent, X-File-Size, X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control'
      headers['Access-Control-Max-Age']           = '1728000'
      headers['Access-Control-Allow-Credentials'] = 'true'
      render :text => '', :content_type => 'text/plain'
      return false
    end
  end
   
   
  private

  # execute events      
  def trigger_events
    Ticket::Observer::Notification.transaction
  end

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    @_current_user ||= session[:user_id] &&
    User.find_by_id( session[:user_id] )
  end
  def current_user_set(user)
    @_current_user = user
    set_user
  end

  def authentication_check
    puts 'authentication_check'

#    puts params.inspect

    # check http basic auth
    authenticate_with_http_basic do |user, password|
      puts 'http basic auth check'
      userdata = User.where( :login => user ).first
      message = ''
      if !userdata
        message = 'authentication failed, user'
      else
        if password != userdata.password
          message = 'authentication failed, pw'
        end
      end

      # return auth ok
      if message == ''
        
        # set basic auth user to current user
        current_user_set(userdata)
        return true
      end
      
      # return auth not ok
      render(
        :json   => {
          :error => message,
        },
        :status => :unauthorized
      )
      return false
    end

    # check logon session
    if params['logon_session'] 
      logon_session = ActiveRecord::SessionStore::Session.where( :session_id => params['logon_session'] ).first
      if logon_session
        userdata = User.find( user_id = logon_session.data[:user_id] )
      end

      # set logon session user to current user
      current_user_set(userdata)
      return true
    end

    # return auth not ok (no session exists)
    if !session[:user_id]
      message = 'no valid session, user_id'
      puts message
      render(
        :json => {
          :error  => message,
        },
        :status => :unauthorized
      )
      return false
    end

    # return auth ok
    return true
  end

  # Sets the current user into a named Thread location so that it can be accessed
  # by models and observers
  def set_user
    return if !current_user
    UserInfo.current_user_id = current_user.id
  end

  def log_view (object)
    history_type = History::Type.where( :name => 'viewed' ).first
    if !history_type || !history_type.id
      history_type = History::Type.create(
        :name   => 'viewed'
      )
    end
    history_object = History::Object.where( :name => object.class.name ).first
    if !history_object || !history_object.id
      history_object = History::Object.create(
        :name   => object.class.name
      )
    end
    
    History.create(
      :o_id                        => object.id,
      :history_type_id             => history_type.id,
      :history_object_id           => history_object.id,
      :created_by_id               => current_user.id
    )
  end

  def config_frontend
    
    # config
    config = {}
    Setting.select('name').where( :frontend => true ).each { |setting|
      config[setting.name] = Setting.get(setting.name)
    }
    return config
  end

  def user_data_full (user_id)

    # get user
    user = User.find_fulldata(user_id)

    # do not show password
    user['password'] = ''
 
    # show linked topics and items
    user['links'] = []

    # TEMP: compat. reasons
    user['preferences'] = {} if user['preferences'] == nil

    topic = {
      :title => 'Tickets',
      :items => [
        {
          :url   => '',
          :name  => 'open (' + user['preferences'][:tickets_open].to_s + ')',
          :title => 'Open Tickets',
          :class => 'user-tickets',
          :data  => 'open'
        },
        {
          :url   => '',
          :name  => 'closed (' + user['preferences'][:tickets_closed].to_s + ')',
          :title => 'Closed Tickets',
          :class => 'user-tickets',
          :data  => 'closed'
        }
      ]
    }
    user['links'].push topic

    return user
  end

end
