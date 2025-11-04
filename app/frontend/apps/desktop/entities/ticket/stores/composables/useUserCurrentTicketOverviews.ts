// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { isEqual, keyBy, mapValues } from 'lodash-es'
import { storeToRefs } from 'pinia'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'

import type {
  Exact,
  Overview,
  UserCurrentOverviewOrderingUpdatesSubscription,
  UserCurrentOverviewOrderingUpdatesSubscriptionVariables,
  UserCurrentTicketOverviewsQuery,
  UserCurrentTicketOverviewUpdatesSubscription,
  UserCurrentTicketOverviewUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { getCurrentApp } from '#desktop/currentApp.ts'
import { useUserCurrentTicketOverviewsQuery } from '#desktop/entities/ticket/graphql/queries/userCurrentTicketOverviews.api.ts'
import { UserCurrentOverviewOrderingFullAttributesUpdatesDocument } from '#desktop/entities/ticket/graphql/subscriptions/useCurrentOverviewOrderingFullAttributesUpdates.api.ts'
import { UserCurrentTicketOverviewFullAttributesUpdatesDocument } from '#desktop/entities/ticket/graphql/subscriptions/userCurrentTicketOverviewFullAttributesUpdates.api.ts'

const verifyCurrentRoute = (overviews: Overview[], firstOverview: Overview) => {
  getCurrentApp().runWithContext(() => {
    const router = useRouter()
    const { name: routeName, params } = router.currentRoute.value
    if (routeName !== 'TicketOverview') return

    const currentActiveOverviewName = params.overviewLink
    const activeOverview = overviews.find((overview) => overview.link === currentActiveOverviewName)

    if (!activeOverview) return

    // Edge case: if the last overview is the same as the first overview, we redirect to the dashboard, so no more overview is available
    if (overviews[0].link === firstOverview.link) return router.push('/dashboard')

    router.replace({ name: routeName, params: { overviewLink: firstOverview.link } })
  })
}

const initializeOverviewsSubscriptions = (
  query: QueryHandler<
    UserCurrentTicketOverviewsQuery,
    Exact<{ ignoreUserConditions: boolean; withTicketCount: boolean }>
  >,
) => {
  query.subscribeToMore<
    UserCurrentTicketOverviewUpdatesSubscriptionVariables,
    UserCurrentTicketOverviewUpdatesSubscription
  >({
    document: UserCurrentTicketOverviewFullAttributesUpdatesDocument,
    variables: { ignoreUserConditions: false },
    updateQuery(_, { subscriptionData, previousData }) {
      const ticketOverviews =
        subscriptionData.data.userCurrentTicketOverviewUpdates?.ticketOverviews

      // if we return an empty array here, the actual query will be aborted, because we have fetchPolicy "cache-and-network"
      // if we return existing value, it will throw an error, because "overviews" doesn't exist yet on the query result
      if (!ticketOverviews) return null as unknown as UserCurrentTicketOverviewsQuery

      // if the current active overview is removed/disabled, we need to redirect
      const newOverviews = ticketOverviews
      const previousOverviews = previousData?.userCurrentTicketOverviews ?? []

      // Check if overviews were removed
      if (newOverviews && previousOverviews.length > newOverviews.length) {
        const removedOverviews = previousOverviews.filter(
          (prevOverview) => !newOverviews.some((overview) => overview.id === prevOverview?.id),
        )
        verifyCurrentRoute(removedOverviews as Overview[], newOverviews[0] as Overview)
      }

      return {
        userCurrentTicketOverviews: ticketOverviews,
      } as unknown as UserCurrentTicketOverviewsQuery
    },
  })

  // Subscription for overview ordering updates
  query.subscribeToMore<
    UserCurrentOverviewOrderingUpdatesSubscriptionVariables,
    UserCurrentOverviewOrderingUpdatesSubscription
  >({
    document: UserCurrentOverviewOrderingFullAttributesUpdatesDocument,
    variables: { ignoreUserConditions: false },
    updateQuery(_, { subscriptionData }) {
      const overviews = subscriptionData.data.userCurrentOverviewOrderingUpdates?.overviews

      if (!overviews) return null as unknown as UserCurrentTicketOverviewsQuery

      return {
        userCurrentTicketOverviews: overviews,
      } as UserCurrentTicketOverviewsQuery
    },
  })
}

export const useUserCurrentTicketOverviews = () => {
  const { user } = storeToRefs(useSessionStore())

  const overviewHandler = new QueryHandler(
    useUserCurrentTicketOverviewsQuery({
      withTicketCount: false,
      ignoreUserConditions: false,
    }),
  )

  initializeOverviewsSubscriptions(overviewHandler)

  const overviewsRaw = overviewHandler.result()
  const overviewsLoading = overviewHandler.loading()

  const overviews = computed(() => overviewsRaw.value?.userCurrentTicketOverviews || [])
  const overviewsById = computed(() => keyBy(overviews.value, 'id'))
  const overviewsByInternalId = computed<Record<ID, string>>((currentLookup) => {
    const newLookup = mapValues(keyBy(overviews.value, 'internalId'), 'id')

    if (currentLookup && isEqual(currentLookup, newLookup)) return currentLookup

    return newLookup
  })

  const overviewsByLink = computed(() => keyBy(overviews.value, 'link'))
  const hasOverviews = computed(() => overviews.value.length > 0)

  const overviewIds = computed(() => Object.keys(overviewsById.value))

  const lastUsedOverviews = computed<Record<ID, string>>((currentLastUsedOverviews) => {
    const lastUsedOverviews = user.value?.preferences?.overviews_last_used || {}

    const newLastUsedOverviews = Object.keys(lastUsedOverviews).reduce(
      (result: Record<ID, string>, internalId) => {
        const id = overviewsByInternalId.value[internalId]

        if (id) {
          result[id] = lastUsedOverviews[internalId]
        }
        return result
      },
      {},
    )

    if (currentLastUsedOverviews && isEqual(currentLastUsedOverviews, newLastUsedOverviews)) {
      return currentLastUsedOverviews
    }

    return newLastUsedOverviews
  })

  const overviewsSortedByLastUsedIds = computed<ID[]>((currentSortedLastUsedIds) => {
    const newSortedLastUsedIds = Object.keys(lastUsedOverviews.value).sort((a, b) =>
      lastUsedOverviews.value[b].localeCompare(lastUsedOverviews.value[a]),
    )

    if (currentSortedLastUsedIds && isEqual(currentSortedLastUsedIds, newSortedLastUsedIds))
      return currentSortedLastUsedIds

    return newSortedLastUsedIds
  })

  // Active Overview (foreground)
  const currentTicketOverviewLink = ref('')
  const lastTicketOverviewLink = ref('')

  const setCurrentTicketOverviewLink = (link: string) => {
    // Remember the previous link, so we can use it for some conditions in the background polling.
    lastTicketOverviewLink.value = currentTicketOverviewLink.value

    currentTicketOverviewLink.value = link
  }

  return {
    overviews,
    lastUsedOverviews,
    overviewsSortedByLastUsedIds,
    overviewsById,
    overviewIds,
    overviewsLoading,
    overviewsByLink,
    hasOverviews,
    lastTicketOverviewLink,
    currentTicketOverviewLink,
    setCurrentTicketOverviewLink,
  }
}
