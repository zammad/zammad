# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  USER_REQUIRED = false

  # A user without internal access to the category still reaches published answers —
  #   that is the content of the public help site — but not the editorial lifecycle
  #   around them. Expressing that as a 'FieldScope' keeps the split in one place,
  #   instead of having consumers re-derive the category access for themselves.
  def show?
    return false if !knowledge_base_active?
    return true if access_editor?
    return true if access_reader? && record.visible_internally?

    record.visible? && public_field_scope
  end

  def show_public?
    return false if !knowledge_base_active?

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

  # A deactivated knowledge base has no readable content, for nobody — an editor included. Gating
  #   the read here rather than at each entry point is what covers them all: the answer's REST
  #   endpoint, its GraphQL type, and — through KnowledgeBase::Answer::TranslationPolicy and
  #   ContentPolicy, which both delegate to this — the attachment downloads, which are otherwise
  #   reachable without any session at all for a published answer.
  #   See https://github.com/zammad/zammad/issues/6338
  def knowledge_base_active?
    record.category.knowledge_base.active?
  end

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
    # `created_by`/`updated_by` among them, and not only the editorial fields of the answer itself:
    #   a translation's `updated_by` is who last wrote its text, which is exactly what `edited_by`
    #   withholds - Answer::TranslationPolicy delegates here, so denying it in one place closes both
    #   routes.
    @public_field_scope ||= ApplicationPolicy::FieldScope.new(deny: %i[internal_at archived_at edited_at edited_by created_by updated_by])
  end
end
