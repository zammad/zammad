# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class CalendarsController < ApplicationController
  before_action :authentication_check

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Calendar, params)
  end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Calendar, params)
  end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Calendar, params)
  end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Calendar, params)
  end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Calendar, params)
  end
end
