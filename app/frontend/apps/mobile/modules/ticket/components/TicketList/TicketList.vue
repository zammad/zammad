<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { OrderDirection, TicketsByOverviewQuery } from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import usePagination from '@mobile/composables/usePagination'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import TicketItem from '@mobile/components/Ticket/TicketItem.vue'
import { useInfiniteScroll } from '@vueuse/core'
import { computed } from 'vue'
import { ConfidentTake } from '@shared/types/utils'
import { useTicketsByOverviewQuery } from '../../graphql/queries/ticketsByOverview.api'

interface Props {
  overviewId: string
  orderBy: string
  orderDirection: OrderDirection
}

const props = defineProps<Props>()

const ticketsQuery = new QueryHandler(
  useTicketsByOverviewQuery(() => {
    return {
      overviewId: props.overviewId,
      orderBy: props.orderBy,
      orderDirection: props.orderDirection,
    }
  }),
)

const ticketsResult = ticketsQuery.result()
const loading = ticketsQuery.loading()

type TicketResultItem = ConfidentTake<
  TicketsByOverviewQuery,
  'ticketsByOverview.edges.node'
>

const tickets = computed(
  () =>
    (ticketsResult.value?.ticketsByOverview.edges
      ?.map((n) => n?.node)
      .filter(Boolean) as TicketResultItem[]) || [],
)

const pagination = usePagination(ticketsQuery, 'ticketsByOverview')
useInfiniteScroll(window, async () => {
  if (!loading.value && pagination.hasNextPage) {
    await pagination.fetchNextPage()
  }
})
</script>

<template>
  <CommonLoader :loading="!tickets.length && loading">
    <TicketItem v-for="ticket in tickets" :key="ticket.id" :entity="ticket" />
    <CommonLoader v-if="pagination.loadingNextPage" loading class="mt-4" />
    <div v-if="!tickets.length" class="px-4 py-3 text-center text-base">
      {{ $t('No entries') }}
    </div>
  </CommonLoader>
</template>
