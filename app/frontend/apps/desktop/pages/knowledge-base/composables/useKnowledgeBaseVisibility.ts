// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue, type MaybeRef } from 'vue'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/schema-types.ts'

// Module-level so callers that only need the mapping (e.g. building a list of
//   breadcrumb items) can read it without invoking a composable per item.
// Should be kept in sync with the map in visibilityMeta.ts,
//   which is used to compute the answer icon and color for a given state.
export const knowledgeBaseVisibilityMeta = {
  [EnumKnowledgeBaseVisibility.Draft]: {
    icon: 'pencil-fill',
    class: 'text-stone-200! dark:text-neutral-500!',
  },
  [EnumKnowledgeBaseVisibility.Internal]: { icon: 'lock-fill', class: 'text-blue-800!' },
  [EnumKnowledgeBaseVisibility.Published]: { icon: 'unlock-fill', class: 'text-green-400!' },
  [EnumKnowledgeBaseVisibility.Archived]: {
    icon: 'archive-fill',
    class: 'text-neutral-400! dark:text-neutral-600!',
  },
} as const

export const useKnowledgeBaseVisibility = (
  visibility?: MaybeRef<EnumKnowledgeBaseVisibility | undefined>,
) => {
  const statusMeta = knowledgeBaseVisibilityMeta

  const currentMetaClass = computed(() => {
    const currentVisibility = toValue(visibility)

    return currentVisibility ? statusMeta[currentVisibility].class : undefined
  })

  const currentMetaIcon = computed(() => {
    const currentVisibility = toValue(visibility)

    return currentVisibility ? statusMeta[currentVisibility].icon : undefined
  })

  return { statusMeta, currentMetaClass, currentMetaIcon }
}
