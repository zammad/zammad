<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  active?: boolean
  noActiveBackground?: boolean
}

const props = defineProps<Props>()

const colorClasses = computed(() => {
  if (props.active)
    return props.noActiveBackground
      ? 'text-black dark:text-white'
      : 'bg-white text-black dark:bg-gray-200 dark:text-white'

  return ''
})
</script>

<template>
  <span
    class="-:text-gray-100 -:dark:text-neutral-400 -:transition-colors inline-block text-nowrap rounded-full px-3.5 py-1 text-base outline-none focus-visible:outline-1 focus-visible:outline-offset-1 focus-visible:outline-blue-800"
    :class="[colorClasses]"
  >
    <slot />
  </span>
</template>
