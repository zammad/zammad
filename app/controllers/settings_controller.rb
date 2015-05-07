# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class SettingsController < ApplicationController
  before_action :authentication_check

  # GET /settings
  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Setting, params)
  end

  # GET /settings/1
  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Setting, params)
  end

  # POST /settings
  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Setting, params)
  end

  # PUT /settings/1
  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Setting, params)
  end

  # DELETE /settings/1
  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Setting, params)
  end
end
