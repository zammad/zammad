// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import {
  canBrowseKnowledgeBase,
  canEditKnowledgeBase,
} from '#shared/entities/knowledge-base/utils/knowledgeBaseAccess.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Single source of truth for gating the route (canAccess), the navigation entry, and the
//   app-level preload of the knowledge base store.
export const useKnowledgeBaseAccess = () => {
  const session = useSessionStore()

  const canBrowse = computed(canBrowseKnowledgeBase)

  // What the create and edit routes gate on, on top of the permission their
  //   `requiredPermission` states.
  const canEdit = computed(canEditKnowledgeBase)

  // Reader or editor — the internal knowledge base roles, and only that: this is what tells an
  //   internal user from a public visitor, so availability is deliberately not part of it.
  const canRead = computed(() => session.hasPermission('knowledge_base.*'))

  return { canBrowse, canEdit, canRead }
}
