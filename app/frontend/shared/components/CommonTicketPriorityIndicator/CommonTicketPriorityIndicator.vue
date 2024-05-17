<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketPriority } from './types.ts'

export interface Props {
  priority?: TicketPriority
}

const props = defineProps<Props>()

const priorityClass = computed(() => {
  if (!props.priority || props.priority.defaultCreate) return null

  switch (props.priority.uiColor) {
    case 'high-priority':
      return 'bg-red-dark text-red-bright'
    case 'low-priority':
      return 'bg-blue-highlight text-blue'
    default:
      return 'bg-gray-highlight text-gray'
  }
})

const priorityText = computed(() => {
  if (!props.priority || props.priority.defaultCreate) return null
  return props.priority.name
})
</script>

<template>
  <div
    v-if="priorityText"
    :class="priorityClass"
    class="leading-2 select-none whitespace-nowrap rounded px-2 py-1 text-xs uppercase"
  >
    {{ $t(priorityText) }}
  </div>
</template>
