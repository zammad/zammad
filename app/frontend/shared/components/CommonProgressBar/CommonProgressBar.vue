<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { getProgressBarClasses } from './initializeProgressBarClasses.ts'

export interface Props {
  value?: string
  max?: string
  size?: 'small' | 'normal'
  variant?: 'primary' | 'inverted'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'normal',
  variant: 'primary',
})

const size = computed(() => {
  switch (props.size) {
    case 'small':
      return 'h-1'
    case 'normal':
    default:
      return 'h-2'
  }
})

const variantClass = computed(() => `progress-bar--${props.variant}`)

const classes = getProgressBarClasses()
</script>

<template>
  <progress
    class="progress-bar w-full appearance-none overflow-hidden rounded-full"
    :class="[size, variantClass, classes]"
    tabindex="0"
    :aria-label="$t('Indicating progress')"
    :value="value"
    :max="max"
  />
</template>
