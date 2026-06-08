// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import { useQueryPolling } from '#shared/composables/useQueryPolling.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useOverviewsWithCachedCountQuery } from '../../graphql/queries/overviewsWithCachedCount.api.ts'
import { useUserCurrentTicketOverviewsCountQuery } from '../../graphql/queries/userCurrentTicketOverviewsCount.api.ts'

import type { TicketOverviewQueryPollingConfig } from '../types.ts'

export const useTicketsCountByOverview = (
  overviewIds: ComputedRef<ID[]>,
  pollingOverviewIds: ComputedRef<ID[]>,
  queryPollingConfig: ComputedRef<TicketOverviewQueryPollingConfig>,
) => {
  const overviewWithCachedCountHandler = new QueryHandler(
    useOverviewsWithCachedCountQuery(
      () => ({
        filterOverviewIds: overviewIds.value,
        ignoreUserConditions: false,
        cacheTtl: queryPollingConfig.value.counts.cache_ttl_sec,
      }),
      () => ({
        fetchPolicy: 'network-only',
        enabled: !!pollingOverviewIds.value?.length && !!overviewIds.value?.length,
        context: {
          batch: {
            active: false,
          },
        },
      }),
    ),
  )

  const { startPolling } = useQueryPolling(
    overviewWithCachedCountHandler,
    queryPollingConfig.value.counts.interval_sec * 1000,
    () => ({
      ignoreUserConditions: false,
      filterOverviewIds: pollingOverviewIds.value,
      cacheTtl: queryPollingConfig.value.counts.cache_ttl_sec,
    }),
    () => ({
      enabled: queryPollingConfig.value.enabled,
    }),
  )

  overviewWithCachedCountHandler.watchOnceOnResult(startPolling)

  const ticketOverviewTicketCountHandler = new QueryHandler(
    useUserCurrentTicketOverviewsCountQuery(
      { ignoreUserConditions: false, cacheTtl: 60 },
      {
        fetchPolicy: 'cache-only',
      },
    ),
  )

  const overviewsTicketCount = ticketOverviewTicketCountHandler.result()

  const overviewsTicketCountById = computed(() => {
    const overviewsWithCount = overviewsTicketCount.value?.userCurrentTicketOverviews || []

    return Object.fromEntries(
      overviewsWithCount.map((overview) => [overview.id, overview.cachedTicketCount]),
    )
  })

  return { overviewsTicketCountById, overviewsTicketCount }
}
