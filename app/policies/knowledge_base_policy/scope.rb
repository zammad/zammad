# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    USER_REQUIRED = false

    # How the public help site resolves its knowledge base. A deactivated one is off the air
    #   for everyone — editors included: preview mode is about unpublished *content* in a live
    #   knowledge base, not about a knowledge base that is switched off.
    #   See https://github.com/zammad/zammad/issues/6338
    #
    # Deliberately stricter than KnowledgeBasePolicy#show_any?, which still admits an editor or
    #   reader of an inactive knowledge base — that check answers for the internal stack, this
    #   scope for the public one.
    def resolve
      scope.active
    end
  end
end
