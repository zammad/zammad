# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::TimeAccountingsControllerPolicy < Controllers::ApplicationControllerPolicy
  def index?
    admin_access? || access?
  end

  def show?
    admin_access? || access?
  end

  def create?
    return true if admin_access?

    time_accounting        = Ticket::TimeAccounting.new(ticket: ticket)
    time_accounting_policy = Ticket::TimeAccountingPolicy.new(user, time_accounting)

    if !time_accounting_policy.create?
      return not_authorized(time_accounting_policy.custom_exception)
    end

    true
  end

  private

  def admin_access?
    user.permissions?('admin.time_accounting')
  end

  def ticket
    @ticket ||= Ticket.find(record.params[:ticket_id])
  end

  def access?
    return false if record.params[:ticket_id].blank?

    TicketPolicy.new(user, ticket).update?
  end

  default_permit!('admin.time_accounting')
end
