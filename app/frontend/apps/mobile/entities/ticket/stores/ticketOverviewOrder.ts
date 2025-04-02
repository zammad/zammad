// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { tryOnScopeDispose, watchOnce } from '@vueuse/core'
import { keyBy } from 'lodash-es'
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

import type {
  Overview,
  TicketOverviewsQuery,
  TicketOverviewUpdatesSubscription,
  TicketOverviewUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketOverviewOrderQuery } from '#mobile/entities/ticket/graphql/queries/overviewOrder.api.ts'
import { TicketOverviewUpdatesDocument } from '#mobile/entities/ticket/graphql/subscriptions/ticketOverviewUpdates.api.ts'

import { getTicketOverviewStorage } from '../helpers/ticketOverviewStorage.ts'

export type TicketOverview = Pick<Overview, 'name' | 'id'>

export const useTicketOverviewOrderStore = defineStore(
  'ticketOverviewOrder',
  () => {
    const ticketOverviewOrderHandler = new QueryHandler(
      useTicketOverviewOrderQuery(),
    )

    // Updates the overviews when overviews got added, updated and/or deleted.
    ticketOverviewOrderHandler.subscribeToMore<
      TicketOverviewUpdatesSubscriptionVariables,
      TicketOverviewUpdatesSubscription
    >({
      document: TicketOverviewUpdatesDocument,
      variables: {
        ignoreUserConditions: true,
        withTicketCount: false,
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

    const overviewsRaw = ticketOverviewOrderHandler.result()
    const overviewsLoading = ticketOverviewOrderHandler.loading()

    const overviews = computed(() => {
      if (!overviewsRaw.value?.ticketOverviews) return []

      return overviewsRaw.value.ticketOverviews.filter(
        (overview) => overview?.id,
      )
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
      ticketOverviewOrderHandler.stop()
    })

    return {
      overviews,
      initializing:
        ticketOverviewOrderHandler.operationResult.forceDisabled.value,
      loading: overviewsLoading,
      includedOverviews,
      includedIds,
      overviewsByKey,
      saveOverviews,
    }
  },
)
