# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AddInternal < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(user_data:, send_invite: false)
    UserInfo.with_user_id(current_user.id) do
      new_user = create_user!(user_data)

      send_invite(new_user) if send_invite

      new_user
    end
  end

  private

  def create_user!(user_data)
    Service::User::FilterPermissionAssignments
      .new(current_user: current_user)
      .execute(user_data: user_data)

    set_core_workflow_information(user_data, ::User)
    User.new(user_data).tap(&:save!)
  end

  def send_invite(user)
    return if user.email.blank?

    token = Token.create(action: 'PasswordReset', user_id: user.id)

    NotificationFactory::Mailer.notification(
      template: 'user_invite',
      user:     user,
      objects:  {
        token:        token,
        user:         user,
        current_user: current_user,
      }
    )
  end
end
