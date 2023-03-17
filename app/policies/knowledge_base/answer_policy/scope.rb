# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.permissions?('knowledge_base.editor')
        scope
      else
        scope.published
      end
    end

    private

    def user_required?
      false
    end
  end
end
