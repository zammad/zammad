# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Controllers::ChecklistItemsControllerPolicy < Controllers::ApplicationControllerPolicy
  def create?
    Checklist::ItemPolicy
      .new(user, checklist&.items&.build)
      .create?
  end

  def create_bulk?
    create?
  end

  def show?
    Checklist::ItemPolicy
      .new(user, checklist_item)
      .show?
  end

  def update?
    Checklist::ItemPolicy
      .new(user, checklist_item)
      .update?
  end

  def destroy?
    Checklist::ItemPolicy
      .new(user, checklist_item)
      .destroy?
  end

  private

  def checklist
    if record.params[:ticket_id].present?
      return Checklist.new(ticket: Ticket.lookup(id: record.params[:ticket_id]))
    end

    Checklist.lookup(id: record.params[:checklist_id])
  end

  def checklist_item
    Checklist::Item.lookup(id: record.params[:id])
  end
end
