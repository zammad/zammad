class Ticket::ArticlePolicy < ApplicationPolicy

  def show?
    access?(__method__)
  end

  def create?
    access?(__method__)
  end

  def update?
    return false if !access?(__method__)
    return true if user.permissions?(['ticket.agent', 'admin'])

    not_authorized('ticket.agent or admin permission required')
  end

  def destroy?
    return true if user.permissions?('admin')
    return false if !access?(__method__)
  # don't let edge case exceptions raised in the TicketPolicy stop
  # other possible positive authorization checks
  rescue Pundit::NotAuthorizedError
    # agents can destroy articles of type 'note'
    # which were created by themselves within the last 10 minutes
    return missing_admin_permission if !user.permissions?('ticket.agent')
    return missing_admin_permission if record.created_by_id != user.id
    return missing_admin_permission if record.type.communication?
    return too_old_to_undo if record.created_at <= 10.minutes.ago

    true
  end

  private

  def access?(query)
    if record.internal == true && user.permissions?('ticket.customer')
      return false
    end

    ticket = Ticket.lookup(id: record.ticket_id)
    Pundit.authorize(user, ticket, query)
  end

  def missing_admin_permission
    not_authorized('admin permission required')
  end

  def too_old_to_undo
    not_authorized('articles more than 10 minutes old may not be deleted')
  end
end
