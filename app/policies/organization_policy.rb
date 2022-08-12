# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

class OrganizationPolicy < ApplicationPolicy

  def show?
    return true if accessible?
    return true if user.organization_id?(record.id)

    false
  end

  def update?
    return true if accessible?

    false
  end

  private

  def accessible?
    user.permissions?(['admin.organization', 'ticket.agent'])
  end
end
