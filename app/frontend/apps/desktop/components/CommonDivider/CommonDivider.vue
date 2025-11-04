<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { DividerOrientation } from './types.ts'

interface Props {
  orientation?: DividerOrientation
  padding?: boolean
  variant?: 'neutral' | 'gray'
}

const props = withDefaults(defineProps<Props>(), {
  orientation: 'horizontal',
  variant: 'neutral',
})

const backgroundClass = computed(() => {
  switch (props.variant) {
    case 'gray':
      return 'bg-white dark:bg-gray-200'
    default: // neutral
      return 'bg-neutral-100 dark:bg-gray-900'
  }
})
</script>

<template>
  <div
    :class="{
      'w-full': props.orientation === 'horizontal',
      'h-full': props.orientation === 'vertical',
      'px-2.5': props.padding && props.orientation === 'horizontal',
      'py-2.5': props.padding && props.orientation === 'vertical',
    }"
  >
    <hr
      class="border-0"
      :class="[
        backgroundClass,
        {
          'h-px w-full': props.orientation === 'horizontal',
          'h-full w-px': props.orientation === 'vertical',
        },
      ]"
    />
  </div>
</template>
