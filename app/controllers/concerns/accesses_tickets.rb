module AccessesTickets
  extend ActiveSupport::Concern

  private

  def ticket_permission(ticket)
    return true if ticket.permission(current_user: current_user)
    raise Exceptions::NotAuthorized
  end
end
