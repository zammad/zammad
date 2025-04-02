# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class RolePolicy < ApplicationPolicy
  def show?
    return true if admin?

    if user.role_ids.include? record.id
      return agent? || customer_field_scope
    end

    false
  end

  private

  def admin?
    user.permissions?('admin.role')
  end

  def agent?
    user.permissions?('ticket.agent')
  end

  def customer_field_scope
    # Filter out name as well.
    @customer_field_scope ||= ApplicationPolicy::FieldScope.new(allow: %w[id groups permissions active])
  end
end
