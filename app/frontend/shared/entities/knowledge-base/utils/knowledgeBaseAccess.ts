// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Derived from settings and permission, so it resolves synchronously without a query: everyone
//   when there is publicly available (published) content, plus editors and readers when an
//   internal knowledge base is active.
export const canBrowseKnowledgeBase = () => {
  const { config } = useApplicationStore()

  return Boolean(
    config.kb_active_publicly ||
    (config.kb_active && useSessionStore().hasPermission('knowledge_base.*')),
  )
}

// Editing rights *and* a knowledge base to use them in: an editor of a deactivated knowledge
//   base has nothing to edit or create.
export const canEditKnowledgeBase = () =>
  useSessionStore().hasPermission('knowledge_base.editor') && canBrowseKnowledgeBase()
