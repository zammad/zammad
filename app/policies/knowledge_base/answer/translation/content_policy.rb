# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::Translation::ContentPolicy < ApplicationPolicy
  USER_REQUIRED = false

  delegate :show?,    to: :parent_answer_policy
  delegate :destroy?, to: :parent_answer_policy

  private

  def parent_answer_policy
    Pundit.policy user, parent_answer
  end

  def parent_answer
    record.translation.answer
  end
end
