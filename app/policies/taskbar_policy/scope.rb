# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class TaskbarPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      scope
        .where(user:, callback: Taskbar.taskbar_entities)
        .reorder(:prio)
    end
  end
end
