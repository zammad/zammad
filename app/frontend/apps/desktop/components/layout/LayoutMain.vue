<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { BackgroundVariant } from './types.ts'

export interface Props {
  backgroundVariant?: BackgroundVariant
  noPadding?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  backgroundVariant: 'tertiary',
})

const backgroundVariantClasses = computed(() => {
  switch (props.backgroundVariant) {
    case 'primary':
      return 'bg-blue-50 dark:bg-gray-800'
    case 'tertiary':
    default:
      return 'bg-neutral-50 dark:bg-gray-500'
  }
})
</script>

<template>
  <main
    class="-:overflow-y-auto h-full w-full text-gray-100 dark:text-neutral-400"
    :class="[backgroundVariantClasses, { 'p-4': !noPadding }]"
  >
    <slot />
  </main>
</template>
