<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import CommonLoader from '#desktop/components/CommonLoader/CommonLoader.vue'
import TicketSimpleTable from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/TicketSimpleTable.vue'
import type { TicketRelationAndRecentListItem } from '#desktop/pages/ticket/components/TicketDetailView/TicketSimpleTable/types.ts'
import { useTicketRelationAndRecentTicketListsQuery } from '#desktop/pages/ticket/graphql/queries/ticketRelationAndRecentTicketLists.api.ts'

interface Props {
  customerId: string
  internalTicketId: number
  selectedTicketId?: string
}

const props = defineProps<Props>()

defineEmits<{
  'click-ticket': [TicketRelationAndRecentListItem]
}>()

const ticketRelationAndRecentListsQuery = new QueryHandler(
  useTicketRelationAndRecentTicketListsQuery(
    {
      customerId: props.customerId,
      limit: 10,
      ticketId: props.internalTicketId,
    },
    {
      fetchPolicy: 'cache-and-network',
    },
  ),
)

// :TODO introduce debounced loading
const isLoading = ticketRelationAndRecentListsQuery.loading()

const tableData = ticketRelationAndRecentListsQuery.result()

const ticketsByCustomer = computed(
  () =>
    tableData.value
      ?.ticketsRecentByCustomer as unknown as TicketRelationAndRecentListItem[],
)

const ticketsRecentlyViewed = computed(
  () =>
    tableData.value
      ?.ticketsRecentlyViewed as unknown as TicketRelationAndRecentListItem[],
)
</script>

<template>
  <CommonLoader :loading="isLoading">
    <div class="space-y-6">
      <TicketSimpleTable
        v-if="ticketsByCustomer && ticketsByCustomer.length > 0"
        :label="$t('Recent Customer Tickets')"
        :tickets="ticketsByCustomer"
        :selected-ticket-id="selectedTicketId"
        @click-ticket="$emit('click-ticket', $event)"
      />

      <TicketSimpleTable
        v-if="ticketsRecentlyViewed && ticketsRecentlyViewed.length > 0"
        :label="$t('Recently Viewed Tickets')"
        :selected-ticket-id="selectedTicketId"
        :tickets="ticketsRecentlyViewed"
        @click-ticket="$emit('click-ticket', $event)"
      />
    </div>
  </CommonLoader>
</template>
