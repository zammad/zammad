class TaskbarController < ApplicationController
  before_filter :authentication_check

  def index
    
    current_user_tasks = Taskbar.where(:user_id=>current_user.id)
    model_index_render_result(current_user_tasks)
    
  end

  def show
    taskbar = Taskbar.find(params[:id])

    if taskbar.user_id != current_user.id
      render :json => { :error => 'Not allowed to show this task.' }, :status => :unprocessable_entity
      return
    end
   
    model_show_render_item(taskbar)
  end

  def create

    params[:user_id] = current_user.id
    model_create_render(taskbar,params)

  end

  def update
    params[:user_id] = current_user.id
    taskbar = Taskbar.find(params[:id])

    if taskbar.user_id != current_user.id
      render :json => { :error => 'Not allowed to update this task.' }, :status => :unprocessable_entity
      return
    end
  
    model_update_render_item(taskbar, params)

  end

  def destroy
    
    params[:user_id] = current_user.id
    taskbar = Taskbar.find(params[:id])

    if taskbar.user_id != current_user.id
      render :json => { :error => 'Not allowed to delete this task.' }, :status => :unprocessable_entity
      return
    end
    
    model_destory_render_item(taskbar)
    taskbar.destroy

  end
end
