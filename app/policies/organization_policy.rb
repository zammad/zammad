# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class OrganizationPolicy < ApplicationPolicy

  def show?
    return true if accessible?

    return customer_field_scope if user.organization_id?(record.id)

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

  def customer_field_scope
    @customer_field_scope ||= ApplicationPolicy::FieldScope.new(allow: %i[id name active])
  end
end
