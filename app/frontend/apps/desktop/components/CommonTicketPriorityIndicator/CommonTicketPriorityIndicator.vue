<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

import CommonTicketPriorityIndicatorIcon from './CommonTicketPriorityIndicatorIcon.vue'

import type { TicketPriority } from './types.ts'

export interface Props {
  priority?: TicketPriority
}

const { config } = storeToRefs(useApplicationStore())

const props = defineProps<Props>()

const badgeVariant = computed(() => {
  switch (props.priority?.uiColor) {
    case 'high-priority':
      return 'danger'
    case 'low-priority':
      return 'tertiary'
    default:
      return 'info'
  }
})
</script>

<template>
  <CommonBadge
    :variant="badgeVariant"
    class="uppercase"
    role="status"
    aria-live="polite"
  >
    <CommonTicketPriorityIndicatorIcon
      v-if="config.ui_ticket_priority_icons"
      :ui-color="priority?.uiColor"
    />
    {{ $t(priority?.name) }}
  </CommonBadge>
</template>
