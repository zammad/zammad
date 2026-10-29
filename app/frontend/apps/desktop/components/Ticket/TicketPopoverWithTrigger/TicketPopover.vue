<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketLabel } from '#shared/entities/ticket/types.ts'
import QueryHandler from '#shared/server/apollo/handler/QueryHandler.ts'

import { useTicketInfoForPopoverQuery } from './graphql/queries/ticketInfoForPopover.api.ts'
import TicketPopoverSkeleton from './skeleton/TicketPopoverSkeleton.vue'
import TicketAttributePopover from './TicketAttributePopover.vue'
import TicketContentPopover from './TicketContentPopover.vue'

interface Props {
  ticket: TicketLabel
  withContent?: boolean
}

const props = defineProps<Props>()

const ticketInfoForPopoverQuery = new QueryHandler(
  useTicketInfoForPopoverQuery(
    () => ({ ticketId: props.ticket.id!, withContent: props.withContent }),
    () => ({ enabled: !!props.ticket.id, fetchPolicy: 'cache-and-network' }),
  ),
)

const ticketResult = ticketInfoForPopoverQuery.result()

const ticketData = computed(() => ticketResult.value?.ticket)

const loading = ticketInfoForPopoverQuery.loadingWithoutCachedResult()
</script>

<template>
  <section
    ref="popover-section"
    data-type="popover"
    class="p-3"
    :class="withContent ? 'w-xl max-w-full space-y-3' : 'max-w-md space-y-2'"
  >
    <TicketPopoverSkeleton :loading="loading">
      <template v-if="ticketData">
        <TicketContentPopover v-if="withContent" :ticket="ticketData" />
        <TicketAttributePopover v-else :ticket="ticketData" />
      </template>
    </TicketPopoverSkeleton>
  </section>
</template>
