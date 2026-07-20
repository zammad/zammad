# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  USER_REQUIRED = false

  def show?
    access_editor? || access_reader?
  end

  # Public browsing: anyone may see an active knowledge base (content is
  #   still scoped per user by the category/answer policies).
  def show_public?
    access_editor? || record.active?
  end

  def show_any?
    show? || show_public?
  end

  def update?
    access_editor?
  end

  private

  def access
    @access ||= KnowledgeBase::EffectivePermission.new(user, record).access_effective
  end

  def access_editor?
    access == 'editor'
  end

  def access_reader?
    access == 'reader'
  end
end
