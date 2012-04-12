class GroupsController < ApplicationController
  before_filter :authentication_check

  # GET /groups
  def index
    @groups = Group.all

    render :json => @groups
  end

  # GET /groups/1
  def show
    @group = Group.find(params[:id])

    render :json => @group
  end

  # POST /groups
  def create
    @group = Group.new(params[:group])
    @group.created_by_id = current_user.id

    if @group.save
      render :json => @group, :status => :created
    else
      render :json => @group.errors, :status => :unprocessable_entity
    end
  end

  # PUT /groups/1
  def update
    @group = Group.find(params[:id])

    if @group.update_attributes(params[:group])
      render :json => @group, :status => :ok
    else
      render :json => @group.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /groups/1
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    head :ok
  end
end
