# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class CoreWorkflowsController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

  def index
    model_index_render(CoreWorkflow.changeable, params)
  end

  def show
    model_show_render(CoreWorkflow.changeable, params)
  end

  def create
    model_create_render(CoreWorkflow.changeable, params)
  end

  def update
    model_update_render(CoreWorkflow.changeable, params)
  end

  def destroy
    model_destroy_render(CoreWorkflow.changeable, params)
  end

  def perform
    render json: CoreWorkflow.perform(payload: params, user: current_user)
  end

end
