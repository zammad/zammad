class UsersController < ApplicationController
  before_filter :authentication_check, :except => [:create]

  # GET /users
  def index
    @users = User.all

    @users.each {|i|
#      r = i.roles.select('id, name').where(:active => true)
#      i['roles'] = r
      role_ids            = i.role_ids
      group_ids           = i.group_ids
      organization_id     = i.organization_id
      i[:role_ids]        = role_ids
      i[:group_ids]       = group_ids
      i[:organization_id] = organization_id
    }

    render :json => @users
  end

  # GET /users/1
  def show
#    @user = User.find(params[:id])
    @user = user_data_full(params[:id])

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
        count = User.all.count()
        role_ids = []
        if count <= 2
          role_ids.push Role.where( :name => 'Admin' ).first.id
          role_ids.push Role.where( :name => 'Agent' ).first.id
        else
          role_ids.push Role.where( :name => 'Customer' ).first.id
        end
        @user.role_ids = role_ids

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
end
