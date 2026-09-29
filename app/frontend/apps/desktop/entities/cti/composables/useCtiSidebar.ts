// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createSharedComposable } from '@vueuse/shared'
import { computed } from 'vue'

import type {
  CtiSidebarQuery,
  CtiSidebarUpdatesSubscription,
  CtiSidebarUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useCtiSidebarQuery } from '#desktop/entities/cti/graphql/queries/ctiSidebar.api.ts'
import { CtiSidebarUpdatesDocument } from '#desktop/entities/cti/graphql/subscriptions/ctiSidebarUpdates.api.ts'

import { useCallerNotificationToggle } from './useCallerNotificationToggle.ts'
import { useCtiAccess } from './useCtiAccess.ts'

// Shared, so the navigation entry and the call notification at the app root
//   read the same ringing calls from one query and one subscription.
export const useCtiSidebar = createSharedComposable(() => {
  const session = useSessionStore()

  const { isIntegrationEnabled } = useCtiAccess()

  const { isEnabled: isNotificationEnabled, setEnabled: setNotificationEnabled } =
    useCallerNotificationToggle()

  // The app root asks before login and for every user, so the query waits for
  //   the permission the navigation entry requires anyway.
  const isEnabled = computed(() => isIntegrationEnabled.value && session.hasPermission('cti.agent'))

  const sidebarQuery = new QueryHandler(
    useCtiSidebarQuery(() => ({
      enabled: isEnabled.value,
      fetchPolicy: 'cache-and-network',
    })),
    {
      // A counter in the navigation is no place for an error notification.
      errorCallback: () => false,
      // A short outage skips the general refetch, but the calls that rang
      //   during it have to reach the call notification as a loaded list.
      triggerRefetchOnConnectionReconnect: true,
    },
  )

  // The subscription pushes the same shape the query answers with, so a push
  //   replaces the result as a whole; it starts without a payload.
  sidebarQuery.subscribeToMore<
    CtiSidebarUpdatesSubscriptionVariables,
    CtiSidebarUpdatesSubscription
  >({
    document: CtiSidebarUpdatesDocument,
    updateQuery: (previous, { subscriptionData }) => {
      if (!subscriptionData.data?.ctiSidebarUpdates.sidebar) {
        return null as unknown as CtiSidebarQuery
      }

      return { ctiSidebar: subscriptionData.data.ctiSidebarUpdates.sidebar }
    },
  })

  const sidebarResult = sidebarQuery.result()

  // On during the first load and again during the refetch after a reconnect.
  const isLoading = sidebarQuery.loading()

  // A result left behind by a disabled query, e.g. after a logout, does not count.
  const isLoaded = computed(() => isEnabled.value && sidebarResult.value !== undefined)

  // Like the old navigation menu, the entry stays quiet while the caller
  //   notification is off: neither the counter nor the ringing calls show.
  const unhandledCount = computed(() =>
    isNotificationEnabled.value ? sidebarResult.value?.ctiSidebar.unhandledCount : undefined,
  )

  const ringingCalls = computed(() =>
    isNotificationEnabled.value ? (sidebarResult.value?.ctiSidebar.ringingCalls ?? []) : [],
  )

  return {
    isIntegrationEnabled,
    isLoaded,
    isLoading,
    unhandledCount,
    ringingCalls,
    isNotificationEnabled,
    setNotificationEnabled,
  }
})
