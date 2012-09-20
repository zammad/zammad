class SettingsController < ApplicationController
  before_filter :authentication_check

  # GET /settings
  def index
    model_index_render(Setting, params)
  end

  # GET /settings/1
  def show
    model_show_render(Setting, params)
  end

  # POST /settings
  def create
    model_create_render(Setting, params)
  end

  # PUT /settings/1
  def update
    model_update_render(Setting, params)
  end

  # DELETE /settings/1
  def destroy
    model_destory_render(Setting, params)
  end
end
