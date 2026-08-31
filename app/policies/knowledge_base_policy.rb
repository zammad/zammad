# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  USER_REQUIRED = false

  def show?
    access_editor? || access_reader?
  end

  # The check behind Gql::Types::KnowledgeBaseType, and the widest of the three: granted access to
  #   the knowledge base, or public browsing of an active one — whose content is still scoped per
  #   user by the category and answer policies.
  #
  # Granted access wins over `active?`, so an editor or reader passes even while the knowledge base
  #   is inactive. That is what lets the public help site preview an unpublished one. The new
  #   stack does not depend on it: its resolvers resolve `KnowledgeBase.active.first!` before
  #   returning the type, so an inactive knowledge base never reaches this check.
  def show_any?
    show? || record.active?
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
