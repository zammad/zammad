# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class JobsController < ApplicationController
  before_action :authentication_check

  def index
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_index_render(Job, params)
  end

  def show
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_show_render(Job, params)
  end

  def create
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_create_render(Job, params)
  end

  def update
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_update_render(Job, params)
  end

  def destroy
    deny_if_not_role(Z_ROLENAME_ADMIN)
    model_destory_render(Job, params)
  end
end
