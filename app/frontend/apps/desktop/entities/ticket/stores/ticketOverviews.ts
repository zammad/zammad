// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { differenceInSeconds } from 'date-fns'
import { defaultsDeep, isEqual } from 'lodash-es'
import { acceptHMRUpdate, defineStore } from 'pinia'
import { computed, effectScope, markRaw, onScopeDispose, ref, toRef, watch, type Raw } from 'vue'

import { useQueryPolling } from '#shared/composables/useQueryPolling.ts'
import type {
  TicketsCachedByOverviewQuery,
  TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types.ts'
import { MutationHandler, QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useAuthenticationStore } from '#shared/stores/authentication.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentOverviewUpdateLastUsedMutation } from '#desktop/entities/ticket/graphql/mutations/userCurrentOverviewUpdateLastUsed.api.ts'
import { useTicketsCountByOverview } from '#desktop/entities/ticket/stores/composables/useTicketsCountByOverview.ts'
import { useUserCurrentTicketOverviews } from '#desktop/entities/ticket/stores/composables/useUserCurrentTicketOverviews.ts'

import { useTicketsCachedByOverviewCache } from '../composables/useTicketsCachedByOverviewCache.ts'
import { useTicketsCachedByOverviewLazyQuery } from '../graphql/queries/ticketsCachedByOverview.api.ts'

import type { TicketsByOverviewHandlerItem, TicketOverviewQueryPollingConfig } from './types.ts'

const DEFAULT_CONFIG: TicketOverviewQueryPollingConfig = {
  enabled: true,
  page_size: 30,
  background: {
    calculation_count: 3,
    cache_ttl_sec: 10,
    interval_sec: 10,
    interval_ranges: [
      { threshold_sec: 60 * 60, interval_sec: 15, cache_ttl_sec: 15 }, // 1 hour ago
      { threshold_sec: 2 * 60 * 60, interval_sec: 20, cache_ttl_sec: 20 }, // 2 hours ago
      { threshold_sec: 4 * 60 * 60, interval_sec: 30, cache_ttl_sec: 30 }, // 4 hour ago
      { threshold_sec: 12 * 60 * 60, interval_sec: 45, cache_ttl_sec: 45 }, // 12 hours ago
      { threshold_sec: 24 * 60 * 60, interval_sec: 60, cache_ttl_sec: 60 }, // 1 day ago
      { threshold_sec: 3 * 24 * 60 * 60, interval_sec: 120, cache_ttl_sec: 120 }, // 3 days ago
      { threshold_sec: 7 * 24 * 60 * 60, interval_sec: 180, cache_ttl_sec: 180 }, // 1 week ago
    ],
  },
  foreground: {
    interval_sec: 5,
    cache_ttl_sec: 5,
  },
  counts: {
    interval_sec: 60,
    cache_ttl_sec: 60,
  },
}

export const useTicketOverviewsStore = defineStore('ticketOverviews', () => {
  const user = toRef(useSessionStore(), 'user')
  const config = toRef(useApplicationStore(), 'config')

  const localConfig = useLocalStorage(
    `${user.value?.id}-ticket-overview-query-polling`,
    {}, // no local overrides by default
  )

  const queryPollingConfig = computed<TicketOverviewQueryPollingConfig>(() => {
    const serverConfig = (config.value?.ui_ticket_overview_query_polling ??
      {}) as Partial<TicketOverviewQueryPollingConfig>
    const localConfigValue = localConfig.value as Partial<TicketOverviewQueryPollingConfig>
    const merged = defaultsDeep({}, localConfigValue, serverConfig, DEFAULT_CONFIG)

    // Handle interval_ranges separately - use first defined value instead of merging
    // This allows setting an empty array to disable ranges
    if (localConfigValue.background?.interval_ranges !== undefined) {
      merged.background.interval_ranges = localConfigValue.background.interval_ranges
    } else if (serverConfig.background?.interval_ranges !== undefined) {
      merged.background.interval_ranges = serverConfig.background.interval_ranges
    } else {
      merged.background.interval_ranges = DEFAULT_CONFIG.background.interval_ranges
    }

    return merged
  })

  // Register window.setQueryPollingConfig to allow for manual override for debugging.
  window.setQueryPollingConfig = (
    c?: Partial<TicketOverviewQueryPollingConfig>,
  ): TicketOverviewQueryPollingConfig => {
    if (c) localConfig.value = c
    return queryPollingConfig.value
  }
  window.resetQueryPollingConfig = (): TicketOverviewQueryPollingConfig => {
    localConfig.value = {}
    return queryPollingConfig.value
  }
  window.getCurrentQueryPollingConfig = (): TicketOverviewQueryPollingConfig => {
    return queryPollingConfig.value
  }

  const {
    overviews,
    lastUsedOverviews,
    overviewsSortedByLastUsedIds,
    overviewsLoading,
    overviewsByLink,
    overviewIds,
    overviewsById,
    hasOverviews,
    lastTicketOverviewLink,
    currentTicketOverviewLink,
    setCurrentTicketOverviewLink,
  } = useUserCurrentTicketOverviews()

  const overviewBackgroundPollingIds = computed<ID[]>((currentIds) => {
    if (
      !hasOverviews.value ||
      !queryPollingConfig.value.enabled ||
      !queryPollingConfig.value.background.calculation_count
    )
      return []

    let backgroundIds = overviewsSortedByLastUsedIds.value.slice(
      0,
      queryPollingConfig.value.background.calculation_count,
    )

    if (!backgroundIds.length && currentTicketOverviewLink.value) {
      backgroundIds.push(overviews.value[0].id)
    }

    backgroundIds = backgroundIds.filter(
      (id) => id !== overviewsByLink.value[currentTicketOverviewLink.value]?.id,
    )

    if (currentIds && isEqual(currentIds, backgroundIds)) return currentIds

    return backgroundIds
  })

  const overviewBackgroundCountPollingIds = computed<ID[]>((currentIds) => {
    if (!hasOverviews.value || !queryPollingConfig.value.enabled) return []

    const backgroundIds = overviewBackgroundPollingIds.value || []

    const remainingIds = overviewIds.value.filter(
      (id) =>
        !backgroundIds.includes(id) &&
        id !== overviewsByLink.value[currentTicketOverviewLink.value]?.id,
    )

    if (currentIds && isEqual(currentIds, remainingIds)) return currentIds

    return remainingIds
  })

  const { overviewsTicketCountById, overviewsTicketCount } = useTicketsCountByOverview(
    overviewIds,
    overviewBackgroundCountPollingIds,
    queryPollingConfig,
  )

  const ticketsByOverviewHandler = ref(new Map<ID, Raw<TicketsByOverviewHandlerItem>>())

  const { readTicketsByOverviewCache } = useTicketsCachedByOverviewCache()

  // Extract shared logic for calculating values based on time-based ranges.
  // This helper handles the common pattern of finding the appropriate value
  // from a list of threshold-based ranges, given how long since last use.
  const calculateValueFromRanges = (
    overviewId: ID,
    key: 'interval_sec' | 'cache_ttl_sec',
  ): number => {
    const ranges = queryPollingConfig.value.background.interval_ranges
    const defaultValue = queryPollingConfig.value.background[key]

    if (!ranges || ranges.length === 0) {
      return defaultValue
    }

    const lastUsedAt = lastUsedOverviews.value[overviewId]
    if (!lastUsedAt) {
      return defaultValue
    }

    const secondsSinceLastUsed = differenceInSeconds(new Date(), new Date(lastUsedAt))

    // Early return if even the smallest threshold is not met. Ranges should be
    // sorted by threshold_sec in ascending order.
    if (secondsSinceLastUsed < ranges[0].threshold_sec) {
      return defaultValue
    }

    // Find the highest threshold that is met by checking from highest to lowest.
    // Using find() which stops early when a match is found.
    const matchedRange = [...ranges]
      .reverse()
      .find((range) => secondsSinceLastUsed >= range.threshold_sec)

    return matchedRange ? ((matchedRange[key] as number | undefined) ?? defaultValue) : defaultValue
  }

  const calculatePollingInterval = (overviewId: ID): number => {
    return calculateValueFromRanges(overviewId, 'interval_sec')
  }

  const calculateCacheTtl = (overviewId: ID): number => {
    return calculateValueFromRanges(overviewId, 'cache_ttl_sec')
  }

  const addTicketByOverviewHandler = (overviewId: ID) => {
    const overview = overviewsById.value[overviewId]

    if (!overview) return

    const scope = effectScope(true)

    const result = scope.run(
      (): {
        handler: QueryHandler<TicketsCachedByOverviewQuery, TicketsCachedByOverviewQueryVariables>
      } => {
        const firstCacheTtl = calculateCacheTtl(overviewId)

        const getMainVariables = () => ({
          overviewId,
          orderBy: overviewsById.value[overviewId].orderBy,
          orderDirection: overviewsById.value[overviewId].orderDirection,
          cacheTtl: firstCacheTtl,
        })

        // TODO: maybe we can use same variables here and afterwards?
        const cachedTickets = readTicketsByOverviewCache(getMainVariables())

        const cachedCollectionSignature =
          cachedTickets?.ticketsCachedByOverview?.collectionSignature

        const ticketsQuery = new QueryHandler(
          useTicketsCachedByOverviewLazyQuery(
            () => ({
              pageSize: queryPollingConfig.value.page_size,
              ...getMainVariables(),
              knownCollectionSignature: cachedCollectionSignature,
            }),
            {
              fetchPolicy: 'network-only',
              context: {
                batch: {
                  active: false,
                },
              },
            },
          ),
          {
            errorShowNotification: false, // We do not show notifications for the overview polling query in the background.
          },
        )

        if (lastTicketOverviewLink.value && overviewsByLink.value[lastTicketOverviewLink.value]) {
          // Delay the background polling when it was the previous foreground overview.
          const delayStartTimer = setTimeout(() => {
            ticketsQuery.load()
          }, queryPollingConfig.value.foreground.interval_sec * 1000)

          onScopeDispose(() => {
            clearTimeout(delayStartTimer)
          })
        } else {
          ticketsQuery.load()
        }

        const ticketsResult = ticketsQuery.result()
        const currentCollectionSignature = computed(() => {
          return ticketsResult.value?.ticketsCachedByOverview?.collectionSignature
        })

        const { startPolling } = useQueryPolling(
          ticketsQuery,
          () => calculatePollingInterval(overviewId) * 1000,
          () => ({
            cacheTtl: calculateCacheTtl(overviewId),
            knownCollectionSignature: currentCollectionSignature.value,
          }),
          {
            randomize: true,
          },
        )

        ticketsQuery.watchOnceOnResult(startPolling)

        return {
          handler: ticketsQuery,
        }
      },
    )

    if (!result) return scope.stop()

    ticketsByOverviewHandler.value.set(
      overview.id,
      markRaw({
        queryHandler: result.handler,
        scope,
      }),
    )
  }

  const removeTicketByOverviewHandler = (overviewId: ID) => {
    const handler = ticketsByOverviewHandler.value.get(overviewId)
    if (!handler) return
    handler.scope.stop()
    ticketsByOverviewHandler.value.delete(overviewId)
  }

  const removeAllTicketByOverviewHandlers = () => {
    ticketsByOverviewHandler.value.forEach((handler) => {
      handler.scope.stop()
    })
    ticketsByOverviewHandler.value.clear()
  }

  watch(
    overviewBackgroundPollingIds,
    (newBackgroundIds) => {
      // Get currently active handler IDs
      const currentIds = Array.from(ticketsByOverviewHandler.value.keys())

      // Remove handlers that are no longer in background polling
      currentIds.forEach((id) => {
        if (!newBackgroundIds.includes(id)) {
          removeTicketByOverviewHandler(id)
        }
      })

      // Add new handlers for IDs that aren't currently being handled
      newBackgroundIds.forEach((id) => {
        if (!ticketsByOverviewHandler.value.has(id)) {
          addTicketByOverviewHandler(id)
        }
      })
    },
    { immediate: true },
  )

  const useUserCurrentOverviewUpdateLastUsedMutationHandler = new MutationHandler(
    useUserCurrentOverviewUpdateLastUsedMutation(),
  )

  const updateLastUsedOverview = async (overviewId: ID) => {
    const newOverviewsLastUsed = {
      ...lastUsedOverviews.value,
      [overviewId]: new Date().toISOString(),
    }

    if (user.value?.preferences) {
      // Update user preferences with the new mapping using overviewsById
      user.value.preferences.overviews_last_used = Object.fromEntries(
        Object.entries(newOverviewsLastUsed).map(([overviewId, lastUsedAt]) => [
          overviewsById.value[overviewId].internalId,
          lastUsedAt,
        ]),
      )
    }

    const mappedOverviewsLastUsed = Object.entries(newOverviewsLastUsed).map(
      ([overviewId, lastUsedAt]) => ({
        overviewId,
        lastUsedAt,
      }),
    )

    await useUserCurrentOverviewUpdateLastUsedMutationHandler.send({
      overviewsLastUsed: mappedOverviewsLastUsed,
    })
  }

  watch(currentTicketOverviewLink, () => {
    const overviewId = overviewsByLink.value[currentTicketOverviewLink.value]?.id

    if (!overviewId) return

    updateLastUsedOverview(overviewId)
  })

  useAuthenticationStore().registerLogoutCleanup(removeAllTicketByOverviewHandlers)

  return {
    queryPollingConfig,
    overviews,
    overviewsTicketCountById,
    overviewsById,
    overviewsByLink,
    overviewsTicketCount,
    overviewsLoading,
    hasOverviews,
    currentTicketOverviewLink,
    setCurrentTicketOverviewLink,
    ticketsByOverviewHandler,
    lastUsedOverviews,
    overviewsSortedByLastUsedIds,
    overviewBackgroundPollingIds,
    overviewBackgroundCountPollingIds,
    updateLastUsedOverview,
    addTicketByOverviewHandler, // returned to be able to test them
    removeTicketByOverviewHandler, // returned to be able to test them
  }
})

if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useTicketOverviewsStore, import.meta.hot))
}
