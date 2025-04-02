<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

export interface Props {
  uiColor?: Maybe<string>
  withTextColor?: boolean
}

const props = defineProps<Props>()

const icon = computed(() => {
  switch (props.uiColor) {
    case 'high-priority':
      return 'priority-high'
    case 'low-priority':
      return 'priority-low'
    default:
      return 'priority-normal'
  }
})

const textColor = computed(() => {
  if (!props.withTextColor) return ''

  switch (props.uiColor) {
    case 'high-priority':
      return 'text-red-500 dark:text-red-500'
    case 'low-priority':
      return 'text-stone-200 dark:text-neutral-500'
    default:
      return 'text-blue-800'
  }
})
</script>

<template>
  <CommonIcon
    size="xs"
    :name="icon"
    class="ltr:mr-1.5 rtl:ml-1.5"
    :class="textColor"
    decorative
  />
</template>
