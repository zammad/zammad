class ChannelsController < ApplicationController
  before_filter :authentication_check

  # GET /channels
  def index
    @channels = Channel.all

    render :json => @channels
  end

  # GET /channels/1
  def show
    @channel = Channel.find(params[:id])

    render :json => @channel
  end

  # POST /channels
  def create
    
    @channel = Channel.new(params[:channel])
    @channel.created_by_id = current_user.id

    if @channel.save
      render :json => @channel, :status => :created
    else
      render :json => @channel.errors, :status => :unprocessable_entity
    end
  end

  # PUT /channels/1
  def update
    @channel = Channel.find(params[:id])

    if @channel.update_attributes(params[:channel])
      render :json => @channel, :status => :ok
    else
      render :json => @channel.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /channels/1
  def destroy
    @channel = Channel.find(params[:id])
    @channel.destroy

    head :ok
  end
end
