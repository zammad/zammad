<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, useTemplateRef } from 'vue'

import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'

import type { BackgroundVariant } from './types.ts'

export interface Props {
  backgroundVariant?: BackgroundVariant
  noPadding?: boolean
  noScrollable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  backgroundVariant: 'tertiary',
})

const scrollContainer = useTemplateRef('scroll-container')

// FIXME: Warning, not reactive! But do we really need that switchable for the same route?
if (!props.noScrollable) useScrollPosition(scrollContainer)

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
    ref="scroll-container"
    class="h-full w-full text-gray-100 dark:text-neutral-400"
    :class="[
      backgroundVariantClasses,
      {
        'p-4': !noPadding,
        'overflow-y-auto': !noScrollable,
        'overflow-y-hidden': noScrollable,
      },
    ]"
  >
    <slot />
  </main>
</template>
