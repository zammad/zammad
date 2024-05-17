// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { tryOnScopeDispose, watchOnce } from '@vueuse/core'
import { keyBy } from 'lodash-es'
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

import { useTicketOverviewsQuery } from '#shared/entities/ticket/graphql/queries/ticket/overviews.api.ts'
import type {
  TicketOverviewsQuery,
  TicketOverviewUpdatesSubscription,
  TicketOverviewUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import type { ConfidentTake } from '#shared/types/utils.ts'

import { TicketOverviewUpdatesDocument } from '../graphql/subscriptions/ticketOverviewUpdates.api.ts'
import { getTicketOverviewStorage } from '../helpers/ticketOverviewStorage.ts'

export type TicketOverview = ConfidentTake<
  TicketOverviewsQuery,
  'ticketOverviews.edges.node'
>

export const useTicketOverviewsStore = defineStore('ticketOverviews', () => {
  const ticketOverviewHandler = new QueryHandler(
    useTicketOverviewsQuery({ withTicketCount: true }),
  )

  // Updates the overviews when overviews got added, updated and/or deleted.
  ticketOverviewHandler.subscribeToMore<
    TicketOverviewUpdatesSubscriptionVariables,
    TicketOverviewUpdatesSubscription
  >({
    document: TicketOverviewUpdatesDocument,
    variables: {
      withTicketCount: true,
    },
    updateQuery(_, { subscriptionData }) {
      const ticketOverviews =
        subscriptionData.data.ticketOverviewUpdates?.ticketOverviews
      // if we return empty array here, the actual query will be aborted, because we have fetchPolicy "cache-and-network"
      // if we return existing value, it will throw an error, because "overviews" doesn't exist yet on the query result
      if (!ticketOverviews) {
        return null as unknown as TicketOverviewsQuery
      }
      return {
        ticketOverviews,
      }
    },
  })

  const overviewsRaw = ticketOverviewHandler.result()
  const overviewsLoading = ticketOverviewHandler.loading()

  const overviews = computed(() => {
    if (!overviewsRaw.value?.ticketOverviews.edges) return []

    return overviewsRaw.value.ticketOverviews.edges
      .filter((overview) => overview?.node?.id)
      .map((edge) => edge.node)
  })

  const overviewsByKey = computed(() => keyBy(overviews.value, 'id'))

  const storage = getTicketOverviewStorage()

  const includedIds = ref(new Set<string>(storage.getOverviews()))

  const includedOverviews = computed(() => {
    return [...includedIds.value]
      .map((id) => overviewsByKey.value[id])
      .filter(Boolean)
  })

  const saveOverviews = (overviews: TicketOverview[]) => {
    const ids = overviews.map(({ id }) => id)
    storage.saveOverviews(ids)
    includedIds.value = new Set(ids)
  }

  const populateIncludeIds = (overviews: TicketOverview[]) => {
    overviews.forEach((overview) => {
      includedIds.value.add(overview.id)
    })

    saveOverviews(overviews)
  }

  // store overviews in local storage when loaded
  // force it to have something
  if (!includedIds.value.size) {
    if (!overviews.value.length) {
      watchOnce(overviews, populateIncludeIds)
    } else {
      populateIncludeIds(overviews.value)
    }
  }

  tryOnScopeDispose(() => {
    ticketOverviewHandler.stop()
  })

  return {
    overviews,
    initializing: ticketOverviewHandler.operationResult.forceDisabled.value,
    loading: overviewsLoading,
    includedOverviews,
    includedIds,
    overviewsByKey,
    saveOverviews,
  }
})
