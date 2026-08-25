// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

// Whether the current user can browse a knowledge base at all — derived from
//   settings + permission, so it resolves synchronously without a query:
//   everyone when there is publicly available (published) content, plus
//   editors/readers when an internal knowledge base is active.
//
// Single source of truth for gating the route (canAccess), the navigation
//   entry, and the app-level preload of the knowledge base store.
export const useKnowledgeBaseAccess = () => {
  const application = useApplicationStore()
  const session = useSessionStore()

  const canBrowse = computed(() =>
    Boolean(
      application.config.kb_active_publicly ||
      (application.config.kb_active && session.hasPermission('knowledge_base.*')),
    ),
  )

  // Editing rights *and* a knowledge base to use them in: an editor of a deactivated knowledge
  //   base has nothing to edit or create. Both halves together are what the create and edit
  //   routes gate on, on top of the permission their `requiredPermission` states.
  const canEdit = computed(() => session.hasPermission('knowledge_base.editor') && canBrowse.value)

  // Reader or editor — the internal knowledge base roles, and only that: this is what tells an
  //   internal user from a public visitor, so availability is deliberately not part of it.
  const canRead = computed(() => session.hasPermission('knowledge_base.*'))

  return { canBrowse, canEdit, canRead }
}
