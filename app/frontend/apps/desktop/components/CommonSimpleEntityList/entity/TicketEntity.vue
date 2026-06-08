<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { Ticket } from '#shared/graphql/types.ts'

import type { Orientation } from '#desktop/components/CommonPopover/types.ts'
import type { EntityType } from '#desktop/components/CommonSimpleEntityList/types.ts'
import CommonTicketLabel from '#desktop/components/CommonTicketLabel/CommonTicketLabel.vue'
import TicketPopoverWithTrigger from '#desktop/components/Ticket/TicketPopoverWithTrigger.vue'

interface Props {
  entity: Ticket
  context: {
    type: EntityType
    emptyMessage?: string
    hasPopover?: boolean
    popoverOrientation?: Orientation
  }
}

defineProps<Props>()
</script>

<template>
  <TicketPopoverWithTrigger
    v-if="context.hasPopover"
    :popover-config="{ orientation: context.popoverOrientation ?? 'left' }"
    class="-mx-1 flex grow gap-3 rounded-md px-1 py-2 hover:outline hover:outline-blue-600 dark:hover:outline-blue-900"
    trigger-link-active-class="outline-2! outline-blue-800! hover:outline-blue-800!"
    :ticket="entity as Ticket"
  >
    <CommonTicketLabel
      :ticket="entity as TicketById"
      :classes="{ indicator: '-translate-y-2' }"
      no-link
      no-wrap
      with-timestamp
    />
  </TicketPopoverWithTrigger>
  <template v-else>
    <CommonTicketLabel
      class="py-1"
      :ticket="entity as TicketById"
      :classes="{
        label:
          'group-focus-visible:rounded-sm group-focus-visible:outline group-focus-visible:outline-offset-1 group-focus-visible:outline-blue-800!',
        indicator: '-translate-y-2',
      }"
      no-wrap
      with-timestamp
    />
  </template>
</template>
