<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<template>
  <div
    class="widget-container rounded-lg border border-neutral-100 bg-white p-4 dark:border-gray-200 dark:bg-gray-500"
  >
    <h3 class="mb-3 border-b border-neutral-100 pb-2 text-base font-semibold dark:border-gray-200">
      {{ __("Today's Tickets") }}
    </h3>

    <CommonLoader v-if="ticketsQuery.loading().value" />

    <div v-else-if="ticketsQuery.operationError().value" class="text-center text-red-600">
      {{ __('Error loading tickets. Please try again later.') }}
    </div>

    <CommonSimpleTable
      v-else-if="tickets.length > 0"
      :items="tableItems"
      :headers="headers"
      :caption="__('Today\'s Tickets')"
      :on-click-row="goToTicket"
      responsive
    />

    <div v-else class="text-center text-neutral-500">
      {{ __('No tickets created today.') }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'

import { i18n } from '#shared/i18n.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import emitter from '#shared/utils/emitter.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import CommonSimpleTable from '#desktop/components/CommonTable/CommonSimpleTable.vue'
import type { TableItem, TableSimpleHeader } from '#desktop/components/CommonTable/types.ts'

import { useTodaysTicketsQuery } from './graphql/todaysTickets.api.ts'

const __ = i18n.t.bind(i18n)

const router = useRouter()

const ticketsQuery = new QueryHandler(useTodaysTicketsQuery())

const tickets = computed(
  () => ticketsQuery.result().value?.todaysTickets?.edges?.map((edge) => edge.node) || [],
)

const tableItems = computed<TableItem[]>(() =>
  tickets.value.map((ticket) => ({
    id: ticket.id,
    internalId: ticket.internalId,
    number: {
      link: `/tickets/${ticket.internalId}`,
      label: ticket.number,
      internal: true,
    },
    title: ticket.title,
    state: ticket.state?.name,
    stateColorCode: ticket.stateColorCode,
    customer: ticket.customer?.fullname,
    group: ticket.group?.name,
    createdAt: ticket.createdAt,
  })),
)

const headers = computed<TableSimpleHeader[]>(() => [
  {
    key: 'number',
    label: __('Number'),
    type: 'link',
  },
  {
    key: 'title',
    label: __('Title'),
    truncate: true,
  },
  {
    key: 'state',
    label: __('State'),
  },
  {
    key: 'customer',
    label: __('Customer'),
  },
])

const goToTicket = (ticket: TableItem) => {
  router.push(`/tickets/${ticket.internalId}`)
}

const refetchTickets = async () => {
  try {
    await ticketsQuery.refetch()
  } catch (error) {
    console.error("Failed to refetch today's tickets:", error)
  }
}

onMounted(() => {
  emitter.on('ticket-created', refetchTickets)
})

onUnmounted(() => {
  emitter.off('ticket-created', refetchTickets)
})

defineExpose({
  refetchTickets,
})
</script>
