# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  def show?
    access_editor? || access_reader?
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
