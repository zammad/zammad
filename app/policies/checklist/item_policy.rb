# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::ItemPolicy < ApplicationPolicy
  delegate :show?, :update?, to: :checklist_policy

  def create?
    checklist_policy.update?
  end

  def destroy?
    checklist_policy.update?
  end

  private

  def checklist_policy
    ChecklistPolicy.new(user, record&.checklist)
  end
end
