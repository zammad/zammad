class SettingsController < ApplicationController
  before_filter :authentication_check

  # GET /settings
  # GET /settings.json
  def index
    @settings = Setting.all

    respond_to do |format|
      format.json { render :json => @settings }
    end
  end

  # GET /settings/1
  # GET /settings/1.json
  def show
    @setting = Setting.find(params[:id])

    respond_to do |format|
      format.json { render :json => @setting }
    end
  end

  # GET /settings/new
  # GET /settings/new.json
  def new
    @setting = Setting.new

    respond_to do |format|
      format.json { render :json => @setting }
    end
  end

  # GET /settings/1/edit
  def edit
    @setting = Setting.find(params[:id])
  end

  # POST /settings
  # POST /settings.json
  def create
    @setting = Setting.new(params[:setting])

    respond_to do |format|
      if @setting.save
        format.json { render :json => @setting, :status => :created }
      else
        format.json { render :json => @setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /settings/1
  # PUT /settings/1.json
  def update
    @setting = Setting.find(params[:id])

    respond_to do |format|
      if @setting.update_attributes(params[:setting])
        format.json { render :json => @setting, :status => :ok }
      else
        format.json { render :json => @setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /settings/1
  # DELETE /settings/1.json
  def destroy
    @setting = Setting.find(params[:id])
    @setting.destroy

    respond_to do |format|
      format.json { head :ok }
    end
  end
end
