// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue, type MaybeRef } from 'vue'

import { EnumKnowledgeBaseVisibility } from '#shared/graphql/schema-types.ts'

export const useKnowledgeBaseVisibility = (
  visibility?: MaybeRef<EnumKnowledgeBaseVisibility | undefined>,
) => {
  const statusMeta = {
    [EnumKnowledgeBaseVisibility.Draft]: {
      icon: 'pencil-fill',
      class: 'text-stone-200! dark:text-neutral-500!',
    },
    [EnumKnowledgeBaseVisibility.Internal]: { icon: 'lock-fill', class: 'text-blue-800!' },
    [EnumKnowledgeBaseVisibility.Published]: { icon: 'unlock-fill', class: 'text-green-400!' },
    // TODO: placeholder icon/color for the archived state pending design.
    [EnumKnowledgeBaseVisibility.Archived]: {
      icon: 'eye-slash',
      class: 'text-stone-400! dark:text-neutral-400!',
    },
  } as const

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
