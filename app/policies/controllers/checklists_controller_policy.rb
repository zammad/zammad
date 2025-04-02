# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChecklistsControllerPolicy < Controllers::ApplicationControllerPolicy
  def create?
    Setting.get('checklist') && Pundit.authorize(user, ticket, :agent_update_access?)
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

  private

  def checklist
    Checklist.lookup(id: record.params[:id])
  end

  def ticket
    Ticket.lookup(id: record.params[:ticket_id])
  end
end
