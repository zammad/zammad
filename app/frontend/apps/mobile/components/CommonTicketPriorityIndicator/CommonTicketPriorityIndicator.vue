<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

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
      return 'bg-gray-highlight text-gray'
    default:
      return 'bg-blue-highlight text-blue'
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
    class="rounded px-2 py-1 text-xs leading-2 whitespace-nowrap uppercase select-none"
  >
    {{ $t(priorityText) }}
  </div>
</template>
