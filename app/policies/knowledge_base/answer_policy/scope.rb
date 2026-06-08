# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    USER_REQUIRED = false

    def resolve
      if user&.permissions?('knowledge_base.editor')
        scope
      else
        scope.published
      end
    end
  end
end
