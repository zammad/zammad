# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TaskbarControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    own?
  end

  def update?
    own?
  end

  def destroy?
    own?
  end

  def init?
    true
  end

  private

  def own?
    taskbar = Taskbar.find(record.params[:id])
    return true if taskbar.user_id == user.id

    # current implementation requires this exception type
    # should be replaced by unified way
    not_authorized Exceptions::UnprocessableEntity.new __('Not allowed to access this task.')
  end
end
