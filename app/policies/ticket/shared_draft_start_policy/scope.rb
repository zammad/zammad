# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStartPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      scope.none if !user.permissions?(['ticket.agent'])

      scope.where group_id: user.groups_access('change').map(&:id)
    end
  end
end
