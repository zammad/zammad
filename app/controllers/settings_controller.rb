class SettingsController < ApplicationController
  before_filter :authentication_check

  # GET /settings
  def index
    @settings = Setting.all

    render :json => @settings
  end

  # GET /settings/1
  def show
    @setting = Setting.find(params[:id])

    render :json => @setting
  end

  # POST /settings
  def create
    @setting = Setting.new(params[:setting])

    if @setting.save
      render :json => @setting, :status => :created
    else
      render :json => @setting.errors, :status => :unprocessable_entity
    end
  end

  # PUT /settings/1
  def update
    @setting = Setting.find(params[:id])

    if @setting.update_attributes(params[:setting])
      render :json => @setting, :status => :ok
    else
      render :json => @setting.errors, :status => :unprocessable_entity
    end
  end

  # DELETE /settings/1
  def destroy
    @setting = Setting.find(params[:id])
    @setting.destroy

    head :ok
  end
end
