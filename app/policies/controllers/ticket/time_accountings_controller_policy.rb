# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::Ticket::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    access?
  end

  def show?
    access?
  end

  def create?
    time_accounting        = Ticket::TimeAccounting.new(ticket: ticket)
    time_accounting_policy = Ticket::TimeAccountingPolicy.new(user, time_accounting)

    if !time_accounting_policy.create?
      return not_authorized(time_accounting_policy.custom_exception)
    end

    true
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

  def ticket
    @ticket ||= Ticket.find(record.params[:ticket_id])
  end

  def access?
    TicketPolicy.new(user, ticket).update?
  end
end
