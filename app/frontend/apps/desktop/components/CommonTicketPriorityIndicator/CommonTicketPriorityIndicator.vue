<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import { useApplicationStore } from '#shared/stores/application.ts'

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
      return 'info'
    default:
      return 'warning'
  }
})

const badgeIcon = computed(() => {
  switch (props.priority?.uiColor) {
    case 'high-priority':
      return 'priority-high'
    case 'low-priority':
      return 'priority-low'
    default:
      return 'priority-normal'
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
    <CommonIcon
      v-if="config.ui_ticket_priority_icons"
      size="xs"
      :name="badgeIcon"
      class="ltr:mr-1.5 rtl:ml-1.5"
      decorative
    />
    {{ $t(priority?.name) }}
  </CommonBadge>
</template>
