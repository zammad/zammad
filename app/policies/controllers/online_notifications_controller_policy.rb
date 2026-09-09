# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::OnlineNotificationsControllerPolicy < Controllers::ApplicationControllerPolicy

  def show?
    accessible?
  end

  def update?
    accessible?
  end

  def destroy?
    own?
  end

  private

  # Same rule as the index action: own notification, related object still accessible.
  def accessible?
    OnlineNotification.list(user, limit: nil).exists?(id: record.params[:id])
  end

  def own?
    notification = OnlineNotification.find(record.params[:id])
    notification.user_id == user.id
  end
end
