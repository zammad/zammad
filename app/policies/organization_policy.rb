# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

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
