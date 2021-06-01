# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy

  def show?
    access?('read')
  end

  def create?
    ensure_group!
    access?('create')
  end

  def update?
    access?('change')
  end

  def destroy?
    return true if user.permissions?('admin')

    # This might look like a bug is actually just defining
    # what exception is being raised and shown to the user.
    return false if !access?('delete')

    not_authorized('admin permission required')
  end

  def full?
    access?('full')
  end

  def ensure_group!
    return if record.group_id

    raise Exceptions::UnprocessableEntity, "Group can't be blank"
  end

  def follow_up?
    return true if user.permissions?('ticket.agent') # agents can always reopen tickets, regardless of group configuration
    return true if record.group.follow_up_possible != 'new_ticket' # check if the setting for follow_up_possible is disabled
    return true if record.state.name != 'closed' # check if the ticket state is already closed

    raise Exceptions::UnprocessableEntity, 'Cannot follow-up on a closed ticket. Please create a new ticket.'
  end

  def agent_read_access?
    agent_access?('read')
  end

  private

  def access?(access)
    return true if agent_access?(access)

    customer_access?
  end

  def agent_access?(access)
    return false if !user.permissions?('ticket.agent')
    return true if owner?

    user.group_access?(record.group.id, access)
  end

  def owner?
    record.owner_id == user.id
  end

  def customer_access?
    return false if !user.permissions?('ticket.customer')
    return true if customer?

    shared_organization?
  end

  def customer?
    record.customer_id == user.id
  end

  def shared_organization?
    return false if record.organization_id.blank?
    return false if user.organization_id.blank?
    return false if record.organization_id != user.organization_id

    record.organization.shared?
  end
end
