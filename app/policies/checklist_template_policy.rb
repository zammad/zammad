# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class ChecklistTemplatePolicy < ApplicationPolicy
  def show?
    checklist_feature_enabled? && (agent? || admin?)
  end

  def create?
    checklist_feature_enabled? && admin?
  end

  def update?
    checklist_feature_enabled? && admin?
  end

  def destroy?
    checklist_feature_enabled? && admin?
  end

  private

  def checklist_feature_enabled?
    Setting.get('checklist')
  end

  def agent?
    user.permissions?('ticket.agent')
  end

  def admin?
    user.permissions?('admin.checklist')
  end
end
