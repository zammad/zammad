# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  def show?
    return true if user&.permissions?(%w[knowledge_base.editor])

    record.visible? ||
      (user&.permissions?(%w[knowledge_base.reader]) && record.visible_internally?)
  end

  def destroy?
    user&.permissions?(%w[knowledge_base.editor])
  end
end
