# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

module ChecksUserAttributesByCurrentUserPermission
  extend ActiveSupport::Concern

  private

  def check_attributes_by_current_user_permission(params)
    authorize!

    # admins can do whatever they want
    return true if current_user.permissions?('admin.user')

    Service::User::FilterPermissionAssignments.new(current_user: current_user).execute(user_data: params)
  end
end
