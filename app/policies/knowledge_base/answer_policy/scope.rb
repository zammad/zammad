# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::AnswerPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    USER_REQUIRED = false

    def resolve
      scope.visible_on_help_site_to_user(user)
    end
  end
end
