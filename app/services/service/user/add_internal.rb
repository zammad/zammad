# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Service::User::AddInternal < Service::BaseWithCurrentUser
  include Service::Concerns::HandlesCoreWorkflow

  def execute(user_data:)
    Service::User::FilterPermissionAssignments.new(current_user: current_user).execute(user_data: user_data)
    set_core_workflow_information(user_data, ::User)
    User.new(user_data).tap(&:save!)
  end
end
