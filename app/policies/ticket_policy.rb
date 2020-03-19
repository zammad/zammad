class TicketPolicy < ApplicationPolicy

  def show?
    access?('read')
  end

  def create?
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

  def follow_up?
    return true if user.permissions?('ticket.agent') # agents can always reopen tickets, regardless of group configuration
    return true if record.group.follow_up_possible != 'new_ticket' # check if the setting for follow_up_possible is disabled
    return true if record.state.name != 'closed' # check if the ticket state is already closed

    raise Exceptions::UnprocessableEntity, 'Cannot follow-up on a closed ticket. Please create a new ticket.'
  end

  private

  def access?(access)

    # check customer
    if user.permissions?('ticket.customer')

      # access ok if its own ticket
      return true if record.customer_id == user.id

      # check organization ticket access
      return false if record.organization_id.blank?
      return false if user.organization_id.blank?
      return false if record.organization_id != user.organization_id

      return record.organization.shared?
    end

    # check agent

    # access if requester is owner
    return true if record.owner_id == user.id

    # access if requester is in group
    user.group_access?(record.group.id, access)
  end
end
