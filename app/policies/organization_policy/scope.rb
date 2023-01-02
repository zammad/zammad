# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OrganizationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope

    def resolve
      if user.permissions?(['ticket.agent', 'admin.organization'])
        scope.all
      elsif user.organization_id
        scope.where(id: user.all_organization_ids)
      else
        scope.none
      end
    end
  end
end
