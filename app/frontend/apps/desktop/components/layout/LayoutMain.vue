<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, provide, ref } from 'vue'

import { MAIN_LAYOUT_KEY } from '#desktop/components/layout/composables/useMainLayoutContainer.ts'

import type { BackgroundVariant } from './types.ts'

export interface Props {
  backgroundVariant?: BackgroundVariant
  noPadding?: boolean
}

const mainContainer = ref<HTMLElement>()

provide(
  MAIN_LAYOUT_KEY,
  computed(() => mainContainer.value),
)

const props = withDefaults(defineProps<Props>(), {
  backgroundVariant: 'tertiary',
})

const backgroundVariantClasses = computed(() => {
  switch (props.backgroundVariant) {
    case 'primary':
      return 'bg-blue-50 dark:bg-gray-800'
    case 'tertiary':
    default:
      return 'bg-white dark:bg-gray-500'
  }
})
</script>

<template>
  <main
    ref="mainContainer"
    class="h-full w-full overflow-y-auto text-gray-100 dark:text-neutral-400"
    :class="[backgroundVariantClasses, { 'p-4': !noPadding }]"
  >
    <slot />
  </main>
</template>
