# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccountingPolicy < ApplicationPolicy
  def create?
    if !Setting.get 'time_accounting'
      return not_authorized __('Time Accounting is not enabled')
    end

    if !matches_selector?
      return not_authorized __('Ticket does not match Time Accounting Selector')
    end

    ticket_update_access?
  end

  private

  def ticket_update_access?
    TicketPolicy.new(user, record.ticket).update?
  end

  def matches_selector?
    CoreWorkflow.matches_selector?(id: record.id, user: user, selector: Setting.get('time_accounting_selector')[:condition] || {})
  end
end
