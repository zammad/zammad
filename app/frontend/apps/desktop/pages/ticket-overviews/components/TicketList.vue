<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { isEqual } from 'lodash-es'
import { storeToRefs } from 'pinia'
import {
  computed,
  onActivated,
  onDeactivated,
  readonly,
  ref,
  type Ref,
  toRef,
  useTemplateRef,
  watch,
} from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate, useRouter } from 'vue-router'

import { useSorting } from '#shared/composables/list/useSorting.ts'
import { usePagination } from '#shared/composables/usePagination.ts'
import { useQueryPolling } from '#shared/composables/useQueryPolling.ts'
import {
  EnumOrderDirection,
  type TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import hasPermission from '#shared/utils/hasPermission.ts'
import { edgesToArray } from '#shared/utils/helpers.ts'

import CommonButton from '#desktop/components/CommonButton/CommonButton.vue'
import { useSkeletonLoadingCount } from '#desktop/components/CommonTable/composables/useSkeletonLoadingCount.ts'
import { useTicketBulkEdit } from '#desktop/components/Ticket/TicketBulkEditFlyout/useTicketBulkEdit.ts'
import TicketListTable from '#desktop/components/Ticket/TicketListTable.vue'
import { useElementScroll } from '#desktop/composables/useElementScroll.ts'
import { useScrollPosition } from '#desktop/composables/useScrollPosition.ts'
import { useTicketsCachedByOverviewCache } from '#desktop/entities/ticket/composables/useTicketsCachedByOverviewCache.ts'
import { useTicketsCachedByOverviewQuery } from '#desktop/entities/ticket/graphql/queries/ticketsCachedByOverview.api.ts'
import { useTicketOverviewsStore } from '#desktop/entities/ticket/stores/ticketOverviews.ts'
import { useLifetimeCustomerTicketsCount } from '#desktop/entities/user/current/composables/useLifetimeCustomerTicketsCount.ts'
import TicketOverviewsEmptyText from '#desktop/pages/ticket-overviews/components/TicketOverviewsEmptyText.vue'

interface Props {
  overviewId: string
  orderBy: string
  orderDirection: EnumOrderDirection
  headers: string[]
  overviewName: string
  groupBy?: string
  overviewCount?: number
}

const props = defineProps<Props>()

const router = useRouter()

const { readTicketsByOverviewCache, forceTicketsByOverviewCacheOnlyFirstPage } =
  useTicketsCachedByOverviewCache()

const { queryPollingConfig } = storeToRefs(useTicketOverviewsStore())

let lastFirstPageCollectionSignature: string
const foreground = ref(true)
const pollingInterval = computed(
  () =>
    (foreground.value
      ? queryPollingConfig.value.foreground.interval_sec
      : queryPollingConfig.value.background.interval_sec) * 1000,
)

const ticketsQueryVariables = computed<TicketsCachedByOverviewQueryVariables>(
  (currentVariables) => {
    const newVariables: TicketsCachedByOverviewQueryVariables = {
      pageSize: queryPollingConfig.value.page_size,
      overviewId: props.overviewId,
      orderBy: props.orderBy,
      orderDirection: props.orderDirection,
      cacheTtl: queryPollingConfig.value.foreground.cache_ttl_sec,
      renewCache: currentVariables?.overviewId !== props.overviewId,
    }

    const cachedTickets = readTicketsByOverviewCache(newVariables)

    newVariables.knownCollectionSignature =
      cachedTickets?.ticketsCachedByOverview?.collectionSignature

    if (currentVariables && isEqual(currentVariables, newVariables)) {
      return currentVariables
    }

    return newVariables
  },
)

const ticketsQuery = new QueryHandler(
  useTicketsCachedByOverviewQuery(ticketsQueryVariables, {
    fetchPolicy: 'cache-and-network',
    nextFetchPolicy: 'cache-and-network',
    context: {
      batch: {
        active: false,
      },
    },
  }),
)

const ticketsResult = ticketsQuery.result()
const loading = ticketsQuery.loading()

const isLoadingTickets = computed(() => {
  if (ticketsResult.value !== undefined) return false

  return loading.value
})

const currentCollectionSignature = computed(() => {
  return ticketsResult.value?.ticketsCachedByOverview?.collectionSignature
})

const tickets = computed(() =>
  edgesToArray(ticketsResult.value?.ticketsCachedByOverview),
)

onActivated(() => {
  if (foreground.value) return

  ticketsQuery.refetch({
    renewCache: true,
  })
  foreground.value = true
})

onDeactivated(() => {
  foreground.value = false
})

const pagination = usePagination(
  ticketsQuery,
  'ticketsCachedByOverview',
  queryPollingConfig.value.page_size,
  () => ({
    knownCollectionSignature: null,
    renewCache: false,
  }),
)

const scrollContainerElement = useTemplateRef('scroll-container')

const {
  sort,
  orderBy: localOrderBy,
  orderDirection: localOrderDirection,
  isSorting,
} = useSorting(
  ticketsQuery,
  toRef(props, 'orderBy'),
  toRef(props, 'orderDirection'),
  scrollContainerElement,
)

const resort = (column: string, direction: EnumOrderDirection) => {
  forceTicketsByOverviewCacheOnlyFirstPage(
    {
      ...ticketsQueryVariables.value,
      orderBy: localOrderBy.value,
      orderDirection: localOrderDirection.value,
    },
    lastFirstPageCollectionSignature,
    queryPollingConfig.value.page_size,
  )

  const cachedTickets = readTicketsByOverviewCache({
    ...ticketsQueryVariables.value,
    orderBy: column,
    orderDirection: direction,
  })

  sort(column, direction, {
    knownCollectionSignature:
      cachedTickets?.ticketsCachedByOverview?.collectionSignature,
    renewCache: false,
  })
}

const { startPolling, stopPolling } = useQueryPolling(
  ticketsQuery,
  pollingInterval,
  () => ({
    knownCollectionSignature: currentCollectionSignature.value,
    renewCache: false,
    pageSize: queryPollingConfig.value.page_size * pagination.currentPage,
  }),
  () => ({
    enabled: queryPollingConfig.value.enabled && !isSorting.value,
  }),
)

ticketsQuery.watchOnceOnResult((result) => {
  if (!queryPollingConfig.value.enabled) return

  lastFirstPageCollectionSignature =
    result.ticketsCachedByOverview.collectionSignature

  startPolling()
})

onBeforeRouteLeave(() => {
  forceTicketsByOverviewCacheOnlyFirstPage(
    ticketsQueryVariables.value,
    lastFirstPageCollectionSignature,
    queryPollingConfig.value.page_size,
  )
})

watch(
  () => props.overviewId,
  () => {
    ticketsQuery.watchOnceOnResult((result) => {
      if (!queryPollingConfig.value.enabled) return

      lastFirstPageCollectionSignature =
        result.ticketsCachedByOverview.collectionSignature

      startPolling()
    })
  },
)

onBeforeRouteUpdate(() => {
  forceTicketsByOverviewCacheOnlyFirstPage(
    ticketsQueryVariables.value,
    lastFirstPageCollectionSignature,
    queryPollingConfig.value.page_size,
  )

  if (!queryPollingConfig.value.enabled) return

  stopPolling()
})

ticketsQuery.onResult((result) => {
  if (isSorting.value && !result.loading) {
    // If sorting comes from the cache, we immediately dispose the loading state
    isSorting.value = false
  }
})

const totalCount = computed(
  () => ticketsResult.value?.ticketsCachedByOverview.totalCount || 0,
)

const loadMore = async () => pagination.fetchNextPage()

const { config } = storeToRefs(useApplicationStore())
const { user } = storeToRefs(useSessionStore())

// Scrolling position is preserved when user visits another page and returns to overview page
const { scrollPosition, restoreScrollPosition } = useScrollPosition(
  scrollContainerElement,
)

const resetScrollPosition = () => {
  scrollPosition.value = 0
  restoreScrollPosition()
}

// Reset scroll-position back to the start, when user navigates between overviews
onBeforeRouteUpdate(resetScrollPosition)

const { reachedTop } = useElementScroll(
  scrollContainerElement as Ref<HTMLDivElement>,
)

const { hasAnyTicket } = useLifetimeCustomerTicketsCount()

const isCustomerAndCanCreateTickets = computed(
  () =>
    hasPermission('ticket.customer', user.value?.permissions?.names ?? []) &&
    config.value.customer_ticket_create,
)

const localHeaders = computed(() => {
  const extendedHeaders = [...props.headers]

  extendedHeaders.unshift('stateIcon')

  if (config.value.ui_ticket_priority_icons) {
    extendedHeaders.unshift('priorityIcon')
  }

  return extendedHeaders
})

const { setOnSuccessCallback, checkedTicketIds } = useTicketBulkEdit()

setOnSuccessCallback(() => {
  forceTicketsByOverviewCacheOnlyFirstPage(
    ticketsQueryVariables.value,
    lastFirstPageCollectionSignature,
    queryPollingConfig.value.page_size,
  )

  ticketsQuery.refetch({
    pageSize: queryPollingConfig.value.page_size,
    renewCache: true,
  })

  requestAnimationFrame(() => {
    scrollContainerElement.value?.scrollTo({ top: 0 })
  })
})

onBeforeRouteUpdate(() => checkedTicketIds.value.clear())

const maxItems = computed(() => config.value.ui_ticket_overview_ticket_limit)

const { visibleSkeletonLoadingCount } = useSkeletonLoadingCount(
  toRef(props, 'overviewCount'),
)

defineExpose({ tickets: readonly(tickets) })
</script>

<template>
  <div
    ref="scroll-container"
    class="overflow-y-auto focus-visible:outline-none"
  >
    <TicketListTable
      :table-id="overviewId"
      :caption="$t('Overview: %s', overviewName)"
      :headers="localHeaders"
      :order-by="localOrderBy"
      :order-direction="localOrderDirection"
      :group-by="groupBy"
      :reached-scroll-top="reachedTop"
      :scroll-container="scrollContainerElement"
      :items="tickets"
      :total-count="totalCount"
      :max-items="maxItems"
      :resorting="isSorting"
      :loading="isLoadingTickets"
      :skeleton-loading-count="visibleSkeletonLoadingCount"
      :loading-new-page="pagination.loadingNewPage"
      @load-more="loadMore"
      @sort="resort"
    >
      <template #empty-list>
        <TicketOverviewsEmptyText
          v-if="isCustomerAndCanCreateTickets && !hasAnyTicket"
          class="space-y-2.5"
          :title="$t('Welcome!')"
        >
          <CommonLabel class="block" tag="p">{{
            $t('You have not created a ticket yet.')
          }}</CommonLabel>
          <CommonLabel class="block" tag="p">{{
            $t('The way to communicate with us is this thing called "ticket".')
          }}</CommonLabel>
          <CommonLabel class="block" tag="p">{{
            $t('Please click on the button below to create your first one.')
          }}</CommonLabel>
          <CommonButton
            size="large"
            class="mx-auto !mt-8"
            variant="primary"
            @click="router.push({ name: 'TicketCreate' })"
            >{{ $t('Create your first ticket') }}
          </CommonButton>
        </TicketOverviewsEmptyText>

        <TicketOverviewsEmptyText
          v-else
          :title="$t('Empty Overview')"
          :text="$t('No tickets in this state.')"
          with-illustration
        />
      </template>
    </TicketListTable>
  </div>
</template>
