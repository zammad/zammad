# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  USER_REQUIRED = false

  # A user without internal access to the category still reaches published answers —
  #   that is the content of the public help site — but not the editorial lifecycle
  #   around them. Expressing that as a 'FieldScope' keeps the split in one place,
  #   instead of having consumers re-derive the category access for themselves.
  def show?
    return true if access_editor?
    return true if access_reader? && record.visible_internally?

    record.visible? && public_field_scope
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

  # Who edited an answer, and when it went internal or was archived, is editorial
  #   information — the public site knows publication only.
  def public_field_scope
    @public_field_scope ||= ApplicationPolicy::FieldScope.new(deny: %i[internal_at archived_at edited_at edited_by])
  end
end
