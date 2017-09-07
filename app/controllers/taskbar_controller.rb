# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class TaskbarController < ApplicationController
  prepend_before_action :authentication_check

  def index
    current_user_tasks = Taskbar.where(user_id: current_user.id)
    model_index_render_result(current_user_tasks)
  end

  def show
    taskbar = Taskbar.find(params[:id])
    access(taskbar)
    model_show_render_item(taskbar)
  end

  def create
    model_create_render(Taskbar, params)
  end

  def update
    taskbar = Taskbar.find(params[:id])
    access(taskbar)
    taskbar.with_lock do
      taskbar.update_attributes!(Taskbar.param_cleanup(params))
    end
    model_update_render_item(taskbar)
  end

  def destroy
    taskbar = Taskbar.find(params[:id])
    access(taskbar)
    taskbar.with_lock do
      taskbar.destroy
    end
    model_destroy_render_item()
  end

  private

  def access(taskbar)
    raise Exceptions::UnprocessableEntity, 'Not allowed to access this task.' if taskbar.user_id != current_user.id
  end
end
