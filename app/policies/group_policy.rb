# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class GroupPolicy < ApplicationPolicy
  def show?
    return true if admin?

    return true if user.group_access?(record, 'read')

    if user.permissions?('ticket.customer')
      return group_is_customer_group? || group_has_customer_tickets?
    end

    false
  end

  private

  def admin?
    user.permissions?('admin.group')
  end

  def group_is_customer_group?
    create_group_ids = Setting.get('customer_ticket_create_group_ids')
    return create_group_ids.include?(record.id) if create_group_ids.present?

    true # All groups allowed if 'customer_ticket_create_group_ids' is empty.
  end

  def group_has_customer_tickets?
    # Check if user is customer for any tickets in this group.
    Ticket.exists?(customer: user, group: record)
  end
end
