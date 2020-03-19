class Controllers::OnlineNotificationsControllerPolicy < Controllers::ApplicationControllerPolicy

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
    notification = OnlineNotification.find(record.params[:id])
    notification.user_id == user.id
  end
end
