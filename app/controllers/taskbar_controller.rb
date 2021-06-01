# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TaskbarController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[show update destroy]
  prepend_before_action :authentication_check

  before_action :set_task_user_param, only: %i[create update]

  def index
    current_user_tasks = Taskbar.where(user_id: current_user.id)
    model_index_render_result(current_user_tasks)
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

  private

  def set_task_user_param
    params[:user_id] = current_user.id
  end
end
