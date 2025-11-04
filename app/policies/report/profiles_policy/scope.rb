# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Report::ProfilesPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if !user.permissions?('report')

      # Profiles are optionally role-restricted. If no roles are assigned to a profile,
      # it's available to any user with reporting permission for backward compatibility.
      # If roles are assigned, require the role to be active and assigned to the user.
      scope.left_joins(roles: :users)
           .where(active: true)
           .where('roles.id IS NULL OR (roles.active = ? AND users.id = ?)', true, user.id)
           .distinct
    end
  end
end
