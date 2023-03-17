# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TicketPolicy < ApplicationPolicy

  def show?
    access?('read')
  end

  def create?
    return false if !ensure_group?

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

  def ensure_group?
    return true if record.group_id

    not_authorized Exceptions::UnprocessableEntity.new __("The required value 'group_id' is missing.")
  end

  def follow_up?
    # This method is used to check if a follow-up is possible (mostly based on the configuration).
    # Agents are always allowed to reopen tickets, configuration does not matter.

    return update? if Ticket::StateType.lookup(id: record.state.state_type_id).name != 'closed' # check if the ticket state is already closed
    return true if agent_update_access?

    # Check follow_up_possible configuration, based on the group.
    return true if follow_up_possible? && update?

    not_authorized Exceptions::UnprocessableEntity.new __('Cannot follow-up on a closed ticket. Please create a new ticket.')
  end

  def agent_read_access?
    agent_access?('read')
  end

  def agent_update_access?
    agent_access?('change')
  end

  def create_mentions?
    agent_read_access?
  end

  private

  def follow_up_possible?
    case record.group.follow_up_possible
    when 'yes'
      true
    when 'new_ticket_after_certain_time'
      record.reopen_after_certain_time?
    when 'new_ticket'
      false
    end
  end

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
    return false if !user.organization_id?(record.organization_id)

    record.organization.shared?
  end
end
