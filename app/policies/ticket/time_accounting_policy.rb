# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccountingPolicy < ApplicationPolicy
  def create?
    if !Setting.get 'time_accounting'
      return not_authorized __('Time Accounting is not enabled')
    end

    ticket_create_access? || ticket_update_access?
  end

  private

  def ticket_create_access?
    TicketPolicy.new(user, record.ticket).create?
  end

  def ticket_update_access?
    TicketPolicy.new(user, record.ticket).update?
  end
end
