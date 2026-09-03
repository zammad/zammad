# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::CategoryPolicy < ApplicationPolicy
  USER_REQUIRED = false

  def show?
    return false if !knowledge_base_active?

    access_editor? || access_reader?
  end

  def show_public?
    return false if !knowledge_base_active?

    access_editor? || record.public_content?
  end

  # A user without internal access still reaches a category that has published content below it —
  #   that is the public help site.
  def show_any?
    show? || show_public?
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

  # Whether a category may be added *under* this one. Aliases #update? today, but is deliberately
  #   its own method: the question is about this category, not about creating it, so it must not be
  #   confused with #create? (which asks the parent). Keeping them separate also lets them diverge
  #   without silently changing what the UI offers.
  def create_subcategory?
    access_editor?
  end

  # Whether an answer may be created in this category. The same access as KnowledgeBase::
  #   AnswerPolicy#create?, which resolves it through the answer's category — but asked of the
  #   category alone, because the browse view has no answer to ask about yet.
  def create_answer?
    access_editor?
  end

  # Whether the answers in this category may be deleted. Aliases #update? today, but is
  #   deliberately its own method, for the same reason #create_subcategory? is: keeping the
  #   questions separate lets them diverge without silently changing what the UI offers.
  #
  # KnowledgeBase::AnswerPolicy#destroy? resolves the very same access through the answer's
  #   category, so every answer in one listing gives the same result — asking the category once is
  #   what lets the browse view gate its per-row delete action without asking per row.
  def destroy_answer?
    access_editor?
  end

  # Whether the answers in this category may be edited. The same access as KnowledgeBase::
  #   AnswerPolicy#update?, which resolves it through the answer's category — so every answer
  #   listed under this category gives the same result, and asking the category once saves asking
  #   it once per row.
  def update_answer?
    access_editor?
  end

  def destroy?
    parent_editor?
  end

  private

  # Same gate as KnowledgeBase::AnswerPolicy#knowledge_base_active?, and for the same reason: a
  #   deactivated knowledge base has no readable content, for nobody. Only the reads are gated —
  #   the editing methods are left alone, so nothing about administering a deactivated knowledge
  #   base changes.
  #   See https://github.com/zammad/zammad/issues/6338
  def knowledge_base_active?
    record.knowledge_base.active?
  end

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
    @parent_access ||= KnowledgeBase::EffectivePermission.new(user, record.parent || record.knowledge_base).access_effective
  end

  def parent_editor?
    parent_access == 'editor'
  end
end
