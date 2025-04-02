# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftStartPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      return scope.none if !user.permissions?('ticket.agent')

      scope.where group_id: user.group_ids_access('create')
    end
  end
end
