# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class TemplatePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?('admin.template')
        scope.all
      elsif user.permissions?('ticket.agent')
        scope.active
      else
        scope.none
      end
    end

  end
end
