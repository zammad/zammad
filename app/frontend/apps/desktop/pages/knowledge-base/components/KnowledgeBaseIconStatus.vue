<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import { useKnowledgeBaseVisibility } from '../composables/useKnowledgeBaseVisibility.ts'

import KnowledgeBaseCategoryIcon from './KnowledgeBaseCategoryIcon.vue'

import type { KnowledgeBaseIconSet } from '../types.ts'

interface Props {
  name: string
  set: KnowledgeBaseIconSet
  size?: Sizes
  status?: EnumKnowledgeBaseVisibility
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

const metaIconSize = computed(() => {
  switch (props.size) {
    case 'xs':
      return { width: 6, height: 6 }
    default:
      return { width: 12, height: 12 }
  }
})
</script>

<template>
  <div v-tooltip="$t(tooltipText)" class="relative h-fit">
    <KnowledgeBaseCategoryIcon :name="name" :set="set" :size="size" :class="currentMetaClass" />
    <div
      v-if="currentMetaIcon"
      class="absolute inset-e-0 bottom-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-0.5 ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-500"
    >
      <CommonIcon
        :name="currentMetaIcon"
        decorative
        :fixed-size="metaIconSize"
        :class="currentMetaClass"
      />
    </div>
  </div>
</template>
