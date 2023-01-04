<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type {
  EnumOrderDirection,
  TicketsByOverviewQuery,
} from '@shared/graphql/types'
import { QueryHandler } from '@shared/server/apollo/handler'
import usePagination from '@mobile/composables/usePagination'
import CommonLoader from '@mobile/components/CommonLoader/CommonLoader.vue'
import TicketItem from '@mobile/components/Ticket/TicketItem.vue'
import { useInfiniteScroll } from '@vueuse/core'
import { computed, ref } from 'vue'
import type { ConfidentTake } from '@shared/types/utils'
import { getFocusableElements } from '@shared/utils/getFocusableElements'
import { useTicketsByOverviewQuery } from '../../graphql/queries/ticketsByOverview.api'

interface Props {
  overviewId: string
  maxCount: number
  orderBy: string
  hiddenColumns: string[]
  orderDirection: EnumOrderDirection
}

const props = defineProps<Props>()
const TICKETS_COUNT = 10

const ticketsQuery = new QueryHandler(
  useTicketsByOverviewQuery(() => {
    return {
      pageSize: TICKETS_COUNT,
      overviewId: props.overviewId,
      orderBy: props.orderBy,
      orderDirection: props.orderDirection,
      showUpdatedBy: !props.hiddenColumns.includes('updated_by'),
      showPriority: !props.hiddenColumns.includes('priority'),
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

const totalCount = computed(
  () => ticketsResult.value?.ticketsByOverview.totalCount || 0,
)

const pagination = usePagination(ticketsQuery, 'ticketsByOverview')

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

useInfiniteScroll(window, async () => {
  if (canLoadMore.value) {
    await pagination.fetchNextPage()
  }
})
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
          input-class="py-2 px-4 w-full h-14 text-black formkit-variant-primary:bg-blue rounded-xl select-none"
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
