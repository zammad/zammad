# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class MacroPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?('admin.macro')
        scope.all
      elsif user.permissions?('ticket.agent')
        scope
          .joins('LEFT OUTER JOIN groups_macros ON groups_macros.macro_id = macros.id')
          .distinct
          .where(agent_having_groups)
      else
        scope.none
      end
    end

    private

    def agent_having_groups
      no_assigned_groups = 'groups_macros.group_id IS NULL'

      groups = user.groups.access(:change, :create)

      if groups.any?
        groups_matcher = groups.map(&:id).join(',')
        return "#{no_assigned_groups} OR groups_macros.group_id IN (#{groups_matcher})"
      end

      no_assigned_groups
    end
  end
end
