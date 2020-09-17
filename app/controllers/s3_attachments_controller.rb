class S3AttachmentsController < ApplicationController
  prepend_before_action :authentication_check, except: %i[create, destroy]
  prepend_before_action :authentication_check_only, only: %i[create, destroy]
  before_action :verify_object_permissions, only: %i[destroy]


  def create
    """
    Presign endpoint take the filename posted
    and presign it to our bucket with random hash attached
    @TODO discuss user association?
    """
    render json: {
      url: '',
    }
  end

  def destroy
    Store.remove_item(@file.id)

    render json: {
      success: true,
    }
  end


  private


  def verify_object_permissions
    @file = Store.find(params[:id])

    klass = @file&.store_object&.name&.safe_constantize
    return if klass.send("can_#{params[:action]}_attachment?", @file, current_user)

    raise ActiveRecord::RecordNotFound
  end
end
