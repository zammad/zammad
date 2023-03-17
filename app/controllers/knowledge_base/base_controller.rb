# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::BaseController < ApplicationController
  prepend_before_action :authentication_check
  before_action :authorize!

  def show
    model_show_render(klass, params_for_permission)
  end

  def create
    model_create_render(klass, params_for_permission)
  end

  def update
    model_update_render(klass, params_for_permission)
  end

  def destroy
    model_destroy_render(klass, params_for_permission)
  end

  private

  def params_for_permission
    params.permit klass.agent_allowed_params
  end
end
