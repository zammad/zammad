# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Ticket::SharedDraftZoomPolicy < ApplicationPolicy
  def update?
    access?(__method__)
  end

  def show?
    access?(__method__)
  end

  def destroy?
    access?(__method__)
  end

  private

  def access?(_method)
    TicketPolicy.new(user, record.ticket).agent_update_access?
  end
end
