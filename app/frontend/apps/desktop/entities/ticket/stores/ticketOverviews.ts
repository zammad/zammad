// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useLocalStorage } from '@vueuse/core'
import { defaultsDeep, isEqual } from 'lodash-es'
import { acceptHMRUpdate, defineStore, storeToRefs } from 'pinia'
import {
  computed,
  effectScope,
  markRaw,
  onScopeDispose,
  ref,
  watch,
  type Raw,
} from 'vue'

import { useQueryPolling } from '#shared/composables/useQueryPolling.ts'
import type {
  TicketsCachedByOverviewQuery,
  TicketsCachedByOverviewQueryVariables,
} from '#shared/graphql/types.ts'
import {
  MutationHandler,
  QueryHandler,
} from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useUserCurrentOverviewUpdateLastUsedMutation } from '#desktop/entities/ticket/graphql/mutations/userCurrentOverviewUpdateLastUsed.api.ts'
import { useTicketsCountByOverview } from '#desktop/entities/ticket/stores/composables/useTicketsCountByOverview.ts'
import { useUserCurrentTicketOverviews } from '#desktop/entities/ticket/stores/composables/useUserCurrentTicketOverviews.ts'

import { useTicketsCachedByOverviewCache } from '../composables/useTicketsCachedByOverviewCache.ts'
import { useTicketsCachedByOverviewLazyQuery } from '../graphql/queries/ticketsCachedByOverview.api.ts'

import type {
  TicketsByOverviewHandlerItem,
  TicketOverviewQueryPollingConfig,
} from './types.ts'

const DEFAULT_CONFIG: TicketOverviewQueryPollingConfig = {
  enabled: true,
  page_size: 30,
  background: {
    calculation_count: 3,
    interval_sec: 10,
    cache_ttl_sec: 10,
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
  const { user } = storeToRefs(useSessionStore())
  const { config } = storeToRefs(useApplicationStore())

  const localConfig = useLocalStorage(
    `${user.value?.id}-ticket-overview-query-polling`,
    {}, // no local overrides by default
  )

  const queryPollingConfig = computed<TicketOverviewQueryPollingConfig>(() => {
    const serverConfig = config.value?.ui_ticket_overview_query_polling ?? {}
    return defaultsDeep({}, localConfig.value, serverConfig, DEFAULT_CONFIG)
  })

  // Register window.setQueryPollingConfig to allow for manual override for debugging.
  window.setQueryPollingConfig = (
    c?: Partial<TicketOverviewQueryPollingConfig>,
  ): TicketOverviewQueryPollingConfig => {
    if (c) localConfig.value = c
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

  const { overviewsTicketCountById, overviewsTicketCount } =
    useTicketsCountByOverview(
      overviewIds,
      overviewBackgroundCountPollingIds,
      queryPollingConfig,
    )

  const ticketsByOverviewHandler = ref(
    new Map<ID, Raw<TicketsByOverviewHandlerItem>>(),
  )

  const { readTicketsByOverviewCache } = useTicketsCachedByOverviewCache()

  const addTicketByOverviewHandler = (overviewId: ID) => {
    const overview = overviewsById.value[overviewId]

    if (!overview) return

    const scope = effectScope(true)

    const result = scope.run(
      (): {
        handler: QueryHandler<
          TicketsCachedByOverviewQuery,
          TicketsCachedByOverviewQueryVariables
        >
      } => {
        // TODO: maybe we can use same variables here and afterwards?
        const cachedTickets = readTicketsByOverviewCache({
          overviewId,
          orderBy: overviewsById.value[overviewId].orderBy,
          orderDirection: overviewsById.value[overviewId].orderDirection,
          cacheTtl: queryPollingConfig.value.background.cache_ttl_sec,
        })

        const cachedCollectionSignature =
          cachedTickets?.ticketsCachedByOverview?.collectionSignature

        const ticketsQuery = new QueryHandler(
          useTicketsCachedByOverviewLazyQuery(
            () => ({
              pageSize: queryPollingConfig.value.page_size,
              overviewId,
              orderBy: overviewsById.value[overviewId].orderBy,
              orderDirection: overviewsById.value[overviewId].orderDirection,
              cacheTtl: queryPollingConfig.value.background.cache_ttl_sec,
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
        )

        if (
          lastTicketOverviewLink.value &&
          overviewsByLink.value[lastTicketOverviewLink.value]
        ) {
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
          return ticketsResult.value?.ticketsCachedByOverview
            ?.collectionSignature
        })

        const { startPolling } = useQueryPolling(
          ticketsQuery,
          () => queryPollingConfig.value.background.interval_sec * 1000,
          () => ({
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

  const useUserCurrentOverviewUpdateLastUsedMutationHandler =
    new MutationHandler(useUserCurrentOverviewUpdateLastUsedMutation())

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
    const overviewId =
      overviewsByLink.value[currentTicketOverviewLink.value]?.id

    if (!overviewId) return

    updateLastUsedOverview(overviewId)
  })

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
  import.meta.hot.accept(
    acceptHMRUpdate(useTicketOverviewsStore, import.meta.hot),
  )
}
