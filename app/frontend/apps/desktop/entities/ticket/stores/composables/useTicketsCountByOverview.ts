// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef, watch } from 'vue'

import { useQueryPolling } from '#shared/composables/useQueryPolling.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useOverviewsWithCachedCountLazyQuery } from '../../graphql/queries/overviewsWithCachedCount.api.ts'
import { useUserCurrentTicketOverviewsCountQuery } from '../../graphql/queries/userCurrentTicketOverviewsCount.api.ts'

import type { TicketOverviewQueryPollingConfig } from '../types.ts'

export const useTicketsCountByOverview = (
  overviewIds: ComputedRef<ID[]>,
  pollingOverviewIds: ComputedRef<ID[]>,
  queryPollingConfig: ComputedRef<TicketOverviewQueryPollingConfig>,
) => {
  // TODO: Check situation, when new overview comes in (because of changed permission or newly added).
  const overviewWithCachedCountHandler = new QueryHandler(
    useOverviewsWithCachedCountLazyQuery(
      // FIXME: Apparently, `useLazyQuery` will try to modify passed variables, which can lead to a warning:
      //   [Vue warn] Write operation failed: computed value is readonly
      // () => (
      {
        filterOverviewIds: overviewIds.value,
        ignoreUserConditions: false,
        cacheTtl: queryPollingConfig.value.counts.cache_ttl_sec,
      },
      // ),
      () => ({
        fetchPolicy: 'network-only',
        enabled: !!pollingOverviewIds.value?.length,
        context: {
          batch: {
            active: false,
          },
        },
      }),
    ),
  )

  const watcher = watch(
    overviewIds,
    (currentOverviewIds) => {
      if (!currentOverviewIds?.length) return

      overviewWithCachedCountHandler.load({
        ignoreUserConditions: false,
        filterOverviewIds: currentOverviewIds, // for the initial load fetch all counts for now
        cacheTtl: queryPollingConfig.value.counts.cache_ttl_sec,
      })

      watcher.stop()
    },
    { immediate: true },
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
    const overviewsWithCount =
      overviewsTicketCount.value?.userCurrentTicketOverviews || []

    return Object.fromEntries(
      overviewsWithCount.map((overview) => [
        overview.id,
        overview.cachedTicketCount,
      ]),
    )
  })

  return { overviewsTicketCountById, overviewsTicketCount }
}
