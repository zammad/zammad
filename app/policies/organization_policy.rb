class OrganizationPolicy < ApplicationPolicy

  def show?
    return true if user.permissions?(['admin', 'ticket.agent'])
    return false if !user.permissions?('ticket.customer')

    record.id == user.organization_id
  end

  def update?
    return false if user.permissions?('ticket.customer')

    user.permissions?(['admin', 'ticket.agent'])
  end

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
