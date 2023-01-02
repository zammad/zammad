# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  def show?
    return true if access_editor?

    record.visible? ||
      (access_reader? && record.visible_internally?)
  end

  def show_public?
    access_editor? || record.visible?
  end

  def create?
    access_editor?
  end

  def update?
    access_editor?
  end

  def destroy?
    access_editor?
  end

  def user_required?
    false
  end

  # Compatibility with Ticket policy
  # When using in GQL together with tickets
  # For example Tag mutations
  def agent_update_access?
    access_editor?
  end

  private

  def access
    @access ||= KnowledgeBase::EffectivePermission.new(user, record.category).access_effective
  end

  def access_editor?
    access == 'editor'
  end

  def access_reader?
    access == 'reader'
  end
end
