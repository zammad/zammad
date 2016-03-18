# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TriggersController < ApplicationController
  before_action :authentication_check

  def index
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Trigger, params)
  end

  def show
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Trigger, params)
  end

  def create
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Trigger, params)
  end

  def update
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Trigger, params)
  end

  def destroy
    return if deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Trigger, params)
  end
end
