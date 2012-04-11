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
    
    # return new session data
    render :json => { :session => user, :default_collections => default_collection }, :status => :created
  end

  def show
    
    # no valid sessions
    if !session[:user_id]
      render :json => {
        :error  => 'no valid session',
        :config => config_frontend,
      }
      return
    end

    # Save the user ID in the session so it can be used in
    # subsequent requests
    user = user_data_full( session[:user_id] )

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
#    auth = request.env['rack.auth']
    auth = request.env['omniauth.auth']

    logger.info(auth.inspect)
    if !auth
      logger.info("AUTH IS NULL, SERVICE NOT LINKED TO ACCOUNT")
#      logger.info()
#      logger.info("PROVIDER: #{provider}, UID: #{uid}, EMAIL: #{email}")
    end
    logger.info(1111111)
#    raise auth.to_yaml
    unless @auth = Authorization.find_from_hash(auth)
      # Create a new user or add an auth to existing user, depending on
      # whether there is already a user signed in.
      @auth = Authorization.create_from_hash(auth, current_user)
    end
#    logger.info(2222222)
#    logger.info(@auth)
#    logger.info(@auth.inspect)
#    logger.info(@auth.user)
    # Log the authorizing user in.
#    self.current_user = @auth.user
#    user = @auth.user
#    logger.info(333333333)
#    exit
    session[:user_id] = @auth.user.id

    # redirect to app
    redirect_to '/app#' 
  end
  
  private
    def default_collections
      
      # auto population of default collections
      default_collection = {}
#      default_collection['User']                = User.all
#      # get linked accounts
#      default_collection['User'].each do |user|
#        user['accounts'] = {}
#        authorizations = user.authorizations() || []
#        authorizations.each do | authorization |
#          user['accounts'][authorization.provider] = {
#            :uid      => authorization[:uid],
#            :username => authorization[:username]
#          }
#        end
#      end
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