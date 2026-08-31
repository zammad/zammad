# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBasePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    USER_REQUIRED = false

    # The same exemption as KnowledgeBasePolicy#show_any?, in scope form: an editor gets the
    #   inactive knowledge base too, so the public help site can preview it. Everyone else
    #   only ever sees an active one.
    #
    # Narrower than the policy on purpose: that one grants any effective access to the record
    #   (a reader included), while this one asks for the 'knowledge_base.editor' permission.
    def resolve
      if user&.permissions?('knowledge_base.editor')
        scope
      else
        scope.active
      end
    end
  end
end
