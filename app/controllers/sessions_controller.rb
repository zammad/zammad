class SessionsController < ApplicationController
#  def create
#    render :text => request.env['rack.auth'].inspect
#  end

  # "Create" a login, aka "log the user in"
  def create
    logger.debug 'session create'
#    logger.debug params.inspect
    user = User.authenticate( params[:username], params[:password] )

    # auth failed
    if !user
      render :json => { :error => 'login failed' }, :status => :unprocessable_entity
      return
    end
    
    # do not show password
    user['password'] = ''
    
    user['roles']         = user.roles.select('id, name').where(:active => true)      
    user['groups']        = user.groups.select('id, name').where(:active => true)      
    user['organization']  = user.organization     
    user['organizations'] = user.organizations.select('id, name').where(:active => true)      
    
    # auto population of default collections
    default_collection = default_collections()
    
    # set session user_id
    session[:user_id] = user.id

    # check logon session
    logon_session_key = nil
    if params['logon_session']
      puts 'create sessions session con'
      logon_session_key = Digest::MD5.hexdigest( rand(999999).to_s + Time.new.to_s )
      ActiveRecord::SessionStore::Session.create(
        :session_id => logon_session_key,
        :data => {
          :user_id => user.id
        }
      )
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
    user = user_data_full( user_id )

    # auto population of default collections
    default_collection = default_collections()

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

    render :json => { }
  end
    
  def create_omniauth
    auth = request.env['omniauth.auth']

    if !auth
      logger.info("AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT")

      # redirect to app
      redirect_to '/app#'
    end

    # Create a new user or add an auth to existing user, depending on
    # whether there is already a user signed in.
    authorization = Authorization.find_from_hash(auth)
    if !authorization
      authorization = Authorization.create_from_hash(auth, current_user)
    end

    # Log the authorizing user in.
    session[:user_id] = authorization.user.id

    # redirect to app
    redirect_to '/app#'
  end
  
  private
    def default_collections
      
      # auto population of default collections
      default_collection = {}
      default_collection['Role']                = Role.all
      default_collection['Group']               = Group.all
      default_collection['Organization']        = Organization.all
      default_collection['TicketStateType']     = Ticket::StateType.all
      default_collection['TicketState']         = Ticket::State.all
      default_collection['TicketPriority']      = Ticket::Priority.all
      default_collection['TicketArticleType']   = Ticket::Article::Type.all
      default_collection['TicketArticleSender'] = Ticket::Article::Sender.all
      default_collection['Network']             = Network.all
      default_collection['NetworkCategory']     = Network::Category.all
      default_collection['NetworkCategoryType'] = Network::Category::Type.all
      default_collection['NetworkPrivacy']      = Network::Privacy.all
      return default_collection  
    end
end