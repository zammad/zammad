# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AddInternal < Service::Base
  include Service::Concerns::HandlesCoreWorkflow

  requires_current_user!

  attr_reader :user_data, :send_invite

  def initialize(user_data:, send_invite: false)
    @user_data = user_data
    @send_invite = send_invite
  end

  def execute
    UserInfo.with_user_id(current_user.id) do
      new_user = create_user!(user_data)

      deliver_invite(new_user) if send_invite

      new_user
    end
  end

  private

  def create_user!(user_data)
    Service::User::FilterPermissionAssignments
      .with_current_user(current_user)
      .execute(user_data: user_data)

    set_core_workflow_information(user_data, ::User)
    User.new(user_data).tap(&:save!)
  end

  def deliver_invite(user)
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
