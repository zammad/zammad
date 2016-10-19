# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class JobsController < ApplicationController
  before_action { authentication_check(permission: 'admin.scheduler') }

  def index
    model_index_render(Job, params)
  end

  def show
    model_show_render(Job, params)
  end

  def create
    model_create_render(Job, params)
  end

  def update
    model_update_render(Job, params)
  end

  def destroy
    model_destory_render(Job, params)
  end

end
