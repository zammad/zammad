# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TaskbarController < ApplicationController
  prepend_before_action :authentication_check

  def index
    current_user_tasks = Taskbar.where(user_id: current_user.id)
    model_index_render_result(current_user_tasks)
  end

  def show
    taskbar = Taskbar.find(params[:id])
    access_to_taskbar(taskbar)
    model_create_render(Taskbar, params)
  end

  def create
    task_user(params)
    model_create_render(Taskbar, params)
  end

  def update
    taskbar = Taskbar.find(params[:id])
    access_to_taskbar(taskbar)
    task_user(params)
    model_update_render(Taskbar, params)
  end

  def destroy
    taskbar = Taskbar.find(params[:id])
    access_to_taskbar(taskbar)
    model_destroy_render(Taskbar, params)
  end

  private

  def access_to_taskbar(taskbar)
    raise Exceptions::UnprocessableEntity, 'Not allowed to access this task.' if taskbar.user_id != current_user.id
  end

  def task_user(params)
    params[:user_id] = current_user.id
  end

end
