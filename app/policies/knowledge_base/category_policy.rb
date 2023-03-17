# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::CategoryPolicy < ApplicationPolicy
  def show?
    access_editor? || access_reader?
  end

  def show_public?
    access_editor? || record.public_content?
  end

  def permissions?
    access_editor?
  end

  def create?
    parent_editor?
  end

  def update?
    access_editor?
  end

  def destroy?
    parent_editor?
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

  def parent_access
    @parent_access ||= KnowledgeBase::EffectivePermission.new(user, (record.parent || record.knowledge_base)).access_effective
  end

  def parent_editor?
    parent_access == 'editor'
  end

  def user_required?
    false
  end
end
