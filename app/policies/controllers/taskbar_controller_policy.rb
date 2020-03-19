class Controllers::TaskbarControllerPolicy < Controllers::ApplicationControllerPolicy

  def show?
    own?
  end

  def update?
    own?
  end

  def destroy?
    own?
  end

  private

  def own?
    taskbar = Taskbar.find(record.params[:id])
    return true if taskbar.user_id == user.id

    # current implementation requires this exception type
    # should be replaced by unified way
    raise Exceptions::UnprocessableEntity, 'Not allowed to access this task.'
  end
end
