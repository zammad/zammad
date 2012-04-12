class RolesController < ApplicationController
  before_filter :authentication_check

  # GET /roles
  def index
    @roles = Role.all

    render :json => @roles
  end

  # GET /roles/1
  def show
    @role = Role.find(params[:id])

    render :json => @role
  end

  # GET /roles/new
  def new
    @role = Role.new

    render :json => @role
  end

  # POST /roles
  def create
    @role = Role.new(params[:role])
    @role.created_by_id = current_user.id

    if @role.save
      render :json => @role, :status => :created
    else
      render :json => @role.errors, :status => :unprocessable_entity
    end
  end

  # PUT /roles/1
  def update
    @role = Role.find(params[:id])

    if @role.update_attributes(params[:role])
      render :json => @role, :status => :ok
    else
      render :json => @role.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /roles/1
  def destroy
    @role = Role.find(params[:id])
    @role.destroy

    head :ok
  end
end
