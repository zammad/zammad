# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Checklist::ItemPolicy < ApplicationPolicy
  delegate :show?, :create?, :update?, :destroy?, to: :checklist_policy

  private

  def checklist_policy
    ChecklistPolicy.new(user, record.checklist)
  end
end
