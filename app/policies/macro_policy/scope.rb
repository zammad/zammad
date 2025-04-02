# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class MacroPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve(include_admin: true)
      if include_admin && user.permissions?('admin.macro')
        scope.all
      elsif user.permissions?('ticket.agent')
        agent_macros
      else
        scope.none
      end
    end

    private

    def agent_macros
      accessible_group_ids = user.group_ids_access(%i[change create])

      scope.available_in_groups accessible_group_ids
    end
  end
end
