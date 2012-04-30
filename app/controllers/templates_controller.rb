class TemplatesController < ApplicationController
  before_filter :authentication_check

  # GET /templates
  def index
    @templates = Template.all

    render :json => @templates
  end

  # GET /templates/1
  def show
    @template = Template.find(params[:id])

    render :json => @template
  end

  # POST /templates
  def create
    @template = Template.new(params[:template])
    @template.created_by_id = current_user.id

    if @template.save
      render :json => @template, :status => :created
    else
      render :json => @template.errors, :status => :unprocessable_entity
    end
  end

  # PUT /templates/1
  def update
    @template = Template.find(params[:id])

    if @template.update_attributes(params[:template])
      render :json => @template, :status => :ok
    else
      render :json => @template.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /templates/1
  def destroy
    @template = Template.find(params[:id])
    @template.destroy

    head :ok
  end
end
