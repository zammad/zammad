# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module Gql::Mutations
  class KnowledgeBase::Base < BaseMutation
    description 'Base class for knowledge base mutations.'

    # Editing the knowledge base is an editor's job. Which *objects* an editor may write is decided
    #   per record by KnowledgeBase::CategoryPolicy, since granular permissions can limit a global
    #   editor to a part of the tree.
    requires_permission 'knowledge_base.editor'
  end
end
