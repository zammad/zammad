class UsersController < ApplicationController
  before_filter :authentication_check, :except => [:create, :password_reset_send, :password_reset_verify]

  # GET /users
  def index
    @users = User.all
    @users_all = []
    @users.each {|user|
      @users_all.push user_data_full( user.id )
    }
    render :json => @users_all
  end

  # GET /users/1
  def show
    @user = user_data_full( params[:id] )
    render :json => @user
  end

  # POST /users
  def create
    @user = User.new(params[:user])
    @user.created_by_id = (current_user && current_user.id) || 1
    if @user.save

      # if it's a signup, add user to customer role
      if @user.created_by_id == 1
        
        # check if it's first user
        count     = User.all.count()
        group_ids = []
        role_ids  = []

        # add first user as admin/agent and to all groups
        if count <= 2
          Role.where( :name => [ 'Admin', 'Agent'] ).each { |role|
            role_ids.push role.id
          }
          Group.all().each { |group|
            group_ids.push group.id
          }
          
        # everybody else will go as customer per default
        else
          role_ids.push Role.where( :name => 'Customer' ).first.id
        end
        @user.role_ids  = role_ids
        @user.group_ids = group_ids

      # else do assignment as defined
      else
        if params[:role_ids]
          @user.role_ids = params[:role_ids]
        end
        if params[:group_ids]
          @user.group_ids = params[:group_ids]
        end
      end
      
      # send inviteation if needed
      if params[:invite]
        
#          logger.debug('IIIIIIIIIIIIIIIIIIIIIIIIIIIIII')
#          exit '123'
      end
      render :json => @user, :status => :created
    else
      render :json => @user.errors, :status => :unprocessable_entity
    end
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])

    if @user.update_attributes(params[:user])
      if params[:role_ids]
        @user.role_ids = params[:role_ids]
      end
      if params[:group_ids]
        @user.group_ids = params[:group_ids]
      end
      if params[:organization_ids]
        @user.organization_ids = params[:organization_ids]
      end
      
      @user = user_data_full( params[:id] )
      render :json => @user, :status => :ok
    else
      render :json => @user.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    head :ok
  end

  # POST /users/reset_password
  def password_reset_send
    success = User.password_reset_send( params[:username] )
    if success
      render :json => { :message => 'ok' }, :status => :ok
    else
      render :json => { :message => 'failed' }, :status => :unprocessable_entity
    end
  end

  # get /users/verify_password/:hash
  def password_reset_verify
    if params[:password]
      success = User.password_reset_via_token( params[:token], params[:password] )
    else
      success = User.password_reset_check( params[:token] )
    end
    if success
      render :json => { :message => 'ok' }, :status => :ok
    else
      render :json => { :message => 'failed' }, :status => :unprocessable_entity
    end
  end

end
