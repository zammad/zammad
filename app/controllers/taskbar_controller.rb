class TaskbarController < ApplicationController
  before_filter :authentication_check

  def index

    current_user_tasks = Taskbar.where( :user_id => current_user.id )
    model_index_render_result(current_user_tasks)

  end

  def show
    taskbar = Taskbar.find( params[:id] )
    return if !access(taskbar)

    model_show_render_item(taskbar)
  end

  def create
    params[:user_id] = current_user.id
    model_create_render(Taskbar,params)
  end

  def update
    taskbar = Taskbar.find( params[:id] )
    return if !access(taskbar)

    params[:user_id] = current_user.id
    taskbar.update_attributes!( Taskbar.param_cleanup(params) )
    model_update_render_item(taskbar)
  end

  def destroy
    taskbar = Taskbar.find( params[:id] )
    return if !access(taskbar)

    taskbar.destroy
    model_destory_render_item()
  end

  private
    def access(taskbar)
      if taskbar.user_id != current_user.id
        render :json => { :error => 'Not allowed to access this task.' }, :status => :unprocessable_entity
        return false
      end
      return true
    end
end
