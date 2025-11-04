<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Ticket } from '#shared/graphql/types.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'
import TicketPopoverWithTrigger from '#desktop/components/Ticket/TicketPopoverWithTrigger.vue'

import type { QuickSearchPluginProps } from '../../types.ts'

const props = defineProps<QuickSearchPluginProps>()

const itemLabel = computed(() => {
  if (props.mode === 'recently-viewed') {
    return (props.item as TicketById).title
  }

  return `#${props.item.number} - ${props.item.title}`
})
</script>

<template>
  <TicketPopoverWithTrigger
    :popover-config="{ orientation: 'right' }"
    class="group/item flex grow gap-2 rounded-md px-2 py-3 text-neutral-400 hover:bg-blue-900 hover:no-underline!"
    trigger-link-active-class="outline-2! outline-offset-1! outline-blue-800! hover:outline-blue-800!"
    :ticket="item as Ticket"
  >
    <CommonTicketStateIndicatorIcon
      class="shrink-0"
      icon-size="small"
      :color-code="item.stateColorCode"
      :label="item.state.name"
    />
    <CommonLabel class="block! truncate group-hover/item:text-white">
      {{ itemLabel }}
    </CommonLabel>
  </TicketPopoverWithTrigger>
</template>
