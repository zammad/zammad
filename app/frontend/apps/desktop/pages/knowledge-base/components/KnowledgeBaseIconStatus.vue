<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import KnowledgeBaseCategoryIcon from '#desktop/components/KnowledgeBaseCategoryIcon/KnowledgeBaseCategoryIcon.vue'
import type { KnowledgeBaseIconSet } from '#desktop/entities/knowledge-base/types.ts'

import { useKnowledgeBaseVisibility } from '../composables/useKnowledgeBaseVisibility.ts'

interface Props {
  name: string
  set: KnowledgeBaseIconSet
  size?: Sizes
  status?: EnumKnowledgeBaseVisibility
  horizontal?: boolean
}

const props = defineProps<Props>()

const { currentMetaClass, currentMetaIcon } = useKnowledgeBaseVisibility(toRef(props, 'status'))

const tooltipText = computed(() => {
  switch (props.status) {
    case EnumKnowledgeBaseVisibility.Draft:
      return __('Draft')
    case EnumKnowledgeBaseVisibility.Internal:
      return __('Internal')
    case EnumKnowledgeBaseVisibility.Published:
      return __('Published')
    case EnumKnowledgeBaseVisibility.Archived:
      return __('Archived')
    default:
      return undefined
  }
})

const containerClass = computed(() => {
  if (props.horizontal) return 'flex'
  return 'relative h-fit'
})

const metaContainerClass = computed(() => {
  const baseClasses = ['flex', 'items-center', 'justify-center', 'p-0.5']

  if (props.horizontal) return baseClasses

  return [
    ...baseClasses,
    'absolute',
    'inset-e-0',
    'bottom-0',
    'rounded-full',
    'translate-y-1',
    'ltr:translate-x-2', // eslint-disable-line zammad/zammad-tailwind-ltr
    'rtl:-translate-x-2', // eslint-disable-line zammad/zammad-tailwind-ltr
    'bg-blue-200',
    'dark:bg-gray-500',
  ]
})

const metaIconSize = computed(() => {
  if (props.horizontal) return { width: 8, height: 8 }
  return { width: 12, height: 12 }
})
</script>

<template>
  <div v-tooltip="$t(tooltipText)" role="img" :class="containerClass">
    <KnowledgeBaseCategoryIcon :name="name" :set="set" :size="size" :class="currentMetaClass" />
    <div v-if="currentMetaIcon" :class="metaContainerClass">
      <CommonIcon
        :name="currentMetaIcon"
        decorative
        :fixed-size="metaIconSize"
        :class="currentMetaClass"
      />
    </div>
  </div>
</template>
