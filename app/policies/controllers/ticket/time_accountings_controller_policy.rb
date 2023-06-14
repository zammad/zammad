# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Ticket::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    access?
  end

  def show?
    access?
  end

  def create?
    access?
  end

  def update?
    admin_access?
  end

  def destroy?
    admin_access?
  end

  private

  def admin_access?
    user.permissions?('admin.time_accounting')
  end

  def access?
    ticket_id = record.params[:ticket_id]
    ticket    = Ticket.find ticket_id

    TicketPolicy.new(user, ticket).update?
  end
end
