# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChecklistsControllerPolicy < Controllers::ApplicationControllerPolicy
  def create?
    ChecklistPolicy
      .new(user, ticket&.build_checklist)
      .create?
  end

  def update?
    ChecklistPolicy
      .new(user, checklist)
      .update?
  end

  def destroy?
    ChecklistPolicy
      .new(user, checklist)
      .destroy?
  end

  def show?
    ChecklistPolicy
      .new(user, checklist)
      .show?
  end

  def show_by_ticket?
    user.permissions?('ticket.agent')
  end

  private

  def checklist
    Checklist.lookup(id: record.params[:id])
  end

  def ticket
    Ticket.lookup(id: record.params[:ticket_id])
  end
end
