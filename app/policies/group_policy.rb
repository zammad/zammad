# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class GroupPolicy < ApplicationPolicy
  def show?
    return true if admin?

    return true if user.group_access?(record, %w[read create change])

    if user.permissions?('ticket.customer')
      return group_is_customer_group? || group_has_customer_tickets? ? customer_field_scope : false
    end

    false
  end

  def create_tickets?
    show? && user.group_access?(record.id, :create)
  end

  private

  def admin?
    user.permissions?('admin.group')
  end

  def group_is_customer_group?
    # All groups allowed if 'customer_ticket_create_group_ids' is empty.
    return true if Setting.get('customer_ticket_create_group_ids').blank?

    Group.customer_create_groups_with_parent_ids.include?(record.id)
  end

  def group_has_customer_tickets?
    # Check if user is customer for any tickets in this group.
    Ticket.exists?(customer: user, group: record)
  end

  def customer_field_scope
    @customer_field_scope ||= ApplicationPolicy::FieldScope.new(allow: %w[id name follow_up_possible reopen_time_in_days active])
  end
end
