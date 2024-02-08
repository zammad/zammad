# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

module ChecksUserAttributesByCurrentUserPermission
  extend ActiveSupport::Concern

  private

  def check_attributes_by_current_user_permission(params)
    authorize!

    Service::User::FilterPermissionAssignments.new(current_user: current_user).execute(user_data: params)
  end
end
