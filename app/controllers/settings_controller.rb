# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

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
    return if is_not_role('Admin')
    model_create_render(Setting, params)
  end

  # PUT /settings/1
  def update
    return if is_not_role('Admin')
    model_update_render(Setting, params)
  end

  # DELETE /settings/1
  def destroy
    return if is_not_role('Admin')
    model_destory_render(Setting, params)
  end
end
