# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class MacroPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?('admin.macro')
        scope.all
      elsif user.permissions?('ticket.agent')
        scope
          .left_joins(:groups)
          .group('macros.id')
          .having(agent_having_groups)
      else
        scope.none
      end
    end

    private

    def agent_having_groups
      base_query = 'SELECT Count(*) FROM groups_macros WHERE groups_macros.macro_id = macros.id'

      having = "((#{base_query}) = 0)"

      groups = user.groups.access(:change, :create)

      if groups.any?
        groups_matcher = groups.map(&:id).join(',')
        having += " OR ((#{base_query} AND groups_macros.group_id IN (#{groups_matcher})) > 0)"
      end

      having
    end
  end
end
