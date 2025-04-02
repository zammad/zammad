# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::TimeAccountingPolicy < ApplicationPolicy
  def create?
    if !Setting.get 'time_accounting'
      return not_authorized __('Time Accounting is not enabled')
    end

    agent_create_or_update_access?
  end

  private

  def agent_create_or_update_access?
    policy = TicketPolicy.new(user, record.ticket)

    policy.agent_update_access? || policy.agent_create_access?
  end
end
