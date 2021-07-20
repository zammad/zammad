# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class OrganizationPolicy < ApplicationPolicy

  def show?
    return true if user.permissions?(['admin', 'ticket.agent'])
    return true if record.id == user.organization_id

    false
  end

  def update?
    return true if user.permissions?(['admin', 'ticket.agent'])

    false
  end
end
