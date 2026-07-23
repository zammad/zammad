<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import CommonIcon from '#shared/components/CommonIcon/CommonIcon.vue'
import type { Sizes } from '#shared/components/CommonIcon/types.ts'
import { EnumKnowledgeBaseVisibility } from '#shared/graphql/types.ts'

import { useKnowledgeBaseVisibility } from '../composables/useKnowledgeBaseVisibility.ts'

interface Props {
  name: string
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
</script>

<template>
  <div v-tooltip="$t(tooltipText)" class="relative h-fit">
    <CommonIcon
      :name="name"
      :size="size"
      :class="currentMetaClass"
      class="group-hover:text-black! group-active:text-white! group-hover:dark:text-white!"
    />
    <div
      v-if="currentMetaIcon"
      class="absolute inset-e-0 bottom-0 flex translate-y-1 items-center justify-center rounded-full bg-blue-200 p-0.5 group-hover:bg-blue-600 group-active:bg-blue-800! ltr:translate-x-2 rtl:-translate-x-2 dark:bg-gray-500 group-hover:dark:bg-blue-900"
    >
      <CommonIcon
        :name="currentMetaIcon"
        decorative
        size="xs"
        :class="currentMetaClass"
        class="group-hover:text-black! group-active:text-white! group-hover:dark:text-white!"
      />
    </div>
  </div>
</template>
