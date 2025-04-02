# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TaskbarController < ApplicationController
  prepend_before_action :authenticate_and_authorize!

  before_action :set_task_user_param, only: %i[create update]

  def index
    model_index_render_result(current_user.taskbars)
  end

  def show
    model_create_render(Taskbar, params)
  end

  def create
    model_create_render(Taskbar, params)
  end

  def update
    model_update_render(Taskbar, params)
  end

  def destroy
    model_destroy_render(Taskbar, params)
  end

  def init
    render json: Taskbar::Init.run(current_user)
  end

  private

  def set_task_user_param
    params[:user_id] = current_user.id
  end
end
