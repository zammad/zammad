# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class ChecklistPolicy < ApplicationPolicy
  def show?
    Checklist.for_user(user).exists?(id: record.id)
  end

  def create?
    return false if !TicketPolicy.new(user, record.ticket).update?

    true
  end

  def update?
    return false if !Checklist.for_user(user).exists?(id: record.id)

    true
  end

  def destroy?
    Checklist.for_user(user).exists?(id: record.id)
  end
end
