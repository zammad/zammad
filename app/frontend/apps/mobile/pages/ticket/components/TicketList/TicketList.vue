<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useInfiniteScroll } from '@vueuse/core'
import { computed, ref, watch, watchEffect } from 'vue'

import type { EnumOrderDirection } from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { getFocusableElements } from '#shared/utils/getFocusableElements.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import CommonLoader from '#mobile/components/CommonLoader/CommonLoader.vue'
import TicketItem from '#mobile/components/Ticket/TicketItem.vue'
import usePagination from '#mobile/composables/usePagination.ts'

import { useTicketsByOverviewQuery } from '../../graphql/queries/ticketsByOverview.api.ts'

interface Props {
  overviewId: string
  overviewTicketCount?: number
  maxCount: number
  orderBy: string
  hiddenColumns: string[]
  orderDirection: EnumOrderDirection
}

const props = defineProps<Props>()
const emit = defineEmits<{
  refetch: [status: boolean]
}>()
const TICKETS_COUNT = 10

const ticketsQueryVariables = computed(() => {
  return {
    pageSize: TICKETS_COUNT,
    overviewId: props.overviewId,
    orderBy: props.orderBy,
    orderDirection: props.orderDirection,
    showUpdatedBy: !props.hiddenColumns.includes('updated_by'),
    showPriority: !props.hiddenColumns.includes('priority'),
  }
})

const ticketsQuery = new QueryHandler(
  useTicketsByOverviewQuery(ticketsQueryVariables, {
    fetchPolicy: 'cache-first',
    nextFetchPolicy: 'cache-first',
  }),
)

const ticketsResult = ticketsQuery.result()
const loading = ticketsQuery.loading()

watchEffect(() => {
  emit('refetch', loading.value && !!ticketsResult.value)
})

const tickets = computed(() =>
  edgesToArray(ticketsResult.value?.ticketsByOverview),
)

const totalCount = computed(
  () => ticketsResult.value?.ticketsByOverview.totalCount || 0,
)

const pagination = usePagination(
  ticketsQuery,
  'ticketsByOverview',
  TICKETS_COUNT,
)

// Refetch tickets, when the ticket count for the current overview changed.
watch(
  () => props.overviewTicketCount,
  (overviewTicketCount) => {
    if (overviewTicketCount !== totalCount.value) {
      ticketsQuery.refetch({
        ...ticketsQueryVariables.value,
        pageSize: TICKETS_COUNT * pagination.currentPage,
      })
    }
  },
)

const canLoadMore = computed(() => {
  return (
    !pagination.loadingNewPage &&
    !loading.value &&
    pagination.hasNextPage &&
    tickets.value.length < props.maxCount
  )
})

const mainElement = ref<HTMLElement>()

const loadMore = async () => {
  const links = getFocusableElements(mainElement.value)
  const lastLink = links[links.length - 2]
  await pagination.fetchNextPage()
  lastLink?.focus({ preventScroll: true })
}

useInfiniteScroll(
  window.document,
  async () => {
    if (canLoadMore.value) {
      await pagination.fetchNextPage()
    }
  },
  // distance is needed for iOS Safari, where infinite scroll is not triggered unless
  // it's at the bery bottom of the page, which is hard to achieve with their "bouncy" scroll
  { distance: 150 },
)
</script>

<template>
  <CommonLoader :loading="!tickets.length && loading">
    <section
      v-if="tickets.length"
      ref="mainElement"
      :aria-label="$t('%s tickets found', tickets.length)"
      aria-live="polite"
      :aria-busy="loading"
    >
      <CommonLink
        v-for="ticket in tickets"
        :key="ticket.id"
        :link="`/tickets/${ticket.internalId}`"
      >
        <TicketItem :entity="ticket" />
      </CommonLink>
      <div v-if="canLoadMore" class="mb-4 px-3">
        <FormKit
          wrapper-class="mt-4 text-base flex grow justify-center items-center"
          input-class="py-2 px-4 w-full h-14 text-white formkit-variant-primary:bg-gray-500 rounded-xl select-none"
          type="submit"
          name="load_more"
          @click="loadMore"
        >
          {{ $t('load %s more', TICKETS_COUNT) }}
        </FormKit>
      </div>
    </section>
    <CommonLoader v-if="pagination.loadingNewPage" loading class="mt-4" />
    <div
      v-if="!tickets.length"
      aria-live="polite"
      class="px-4 py-3 text-center text-base"
    >
      {{ $t('No entries') }}
    </div>
    <div
      v-else-if="tickets.length >= maxCount && totalCount > maxCount"
      class="px-4 py-3 text-center text-sm"
      aria-live="polite"
    >
      {{
        $t(
          'The limit of %s displayable tickets was reached (%s remaining)',
          maxCount,
          totalCount - tickets.length,
        )
      }}
    </div>
  </CommonLoader>
</template>
