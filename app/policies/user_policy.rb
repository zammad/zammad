# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class UserPolicy < ApplicationPolicy

  # Use 'nested_show' when looking at a user record that is part of an already
  #   authenticated record, like the owner of a ticket that the user has access to.
  # In that case, customers should have permission to look at some fields even if they
  #   don't have 'show?' permission.
  def nested_show?
    return true if user.permissions?('admin.*')
    return true if own_account? # TODO: check if a customer user may really see all their fields.
    return true if user.permissions?('ticket.agent')

    return false if !user.permissions?('ticket.customer')

    customer_field_scope
  end

  def show?
    return true if user.permissions?('admin.*')
    return true if own_account? # TODO: check if a customer user may really see all their fields.
    return true if user.permissions?('ticket.agent')
    # check same organization for customers
    return false if !user.permissions?('ticket.customer')

    same_organization? ? customer_field_scope : false
  end

  def update?
    # full access for admins
    return true if user.permissions?('admin.user')
    # forbid non-agents to change users
    return false if !user.permissions?('ticket.agent')

    # allow agents to change customers only
    return false if record.permissions?(['admin.user', 'ticket.agent'])

    record.permissions?('ticket.customer')
  end

  def destroy?
    user.permissions?('admin.user')
  end

  private

  def own_account?
    record.id == user.id
  end

  def same_organization?
    return false if record.organization_id.blank?
    return false if user.organization_id.blank?

    user.organization_id?(record.organization_id)
  end

  def customer_field_scope
    @customer_field_scope ||= ApplicationPolicy::FieldScope.new(allow: %i[id firstname lastname image image_source active])
  end
end
