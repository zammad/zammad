class UsersController < ApplicationController
  before_filter :authentication_check, :except => [:create]

  # GET /users
  # GET /users.json
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

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
#    @user = User.find(params[:id])
    @user = user_data_full(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])
    @user.created_by_id = (current_user && current_user.id) || 1
    respond_to do |format|
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
        format.html { redirect_to @user, :notice => 'User was successfully created.' }
        format.json { render :json => @user, :status => :created }
      else
        format.html { render :action => "new" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        if params[:role_ids]
          @user.role_ids = params[:role_ids]
        end
        if params[:group_ids]
          @user.group_ids = params[:group_ids]
        end
        format.html { redirect_to @user, :notice => 'User was successfully updated.' }
        format.json { render :json => @user, :status => :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :ok }
    end
  end
end
