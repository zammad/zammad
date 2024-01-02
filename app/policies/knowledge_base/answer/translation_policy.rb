# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Answer::TranslationPolicy < ApplicationPolicy
  delegate :show?, to: :parent_answer_policy
  delegate :update?, to: :parent_answer_policy

  private

  def parent_answer_policy
    Pundit.policy user, record.answer
  end
end
