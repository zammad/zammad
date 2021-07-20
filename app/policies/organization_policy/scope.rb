# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?(['ticket.agent', 'admin.organization'])
        scope.all
      elsif user.organization_id
        scope.where(id: user.organization_id)
      else
        scope.none
      end
    end
  end
end
