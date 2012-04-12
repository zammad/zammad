class OrganizationsController < ApplicationController
  before_filter :authentication_check

  # GET /organizations
  def index
    @organizations = Organization.all

    render :json => @organizations
  end

  # GET /organizations/1
  def show
    @organization = Organization.find(params[:id])

    render :json => @organization
  end

  # POST /organizations
  def create
    @organization = Organization.new(params[:organization])
    @organization.created_by_id = current_user.id

    if @organization.save
      render :json => @organization, :status => :created
    else
      render :json => @organization.errors, :status => :unprocessable_entity
    end
  end

  # PUT /organizations/1
  def update
    @organization = Organization.find(params[:id])

    if @organization.update_attributes(params[:organization])
      render :json => @organization, :status => :ok
    else
      render :json => @organization.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /organizations/1
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy

    head :ok
  end
end
