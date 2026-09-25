// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type {
  CtiSidebarUpdatesSubscription,
  CtiSidebarUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useCtiSidebarQuery } from '#desktop/entities/cti/graphql/queries/ctiSidebar.api.ts'
import { CtiSidebarUpdatesDocument } from '#desktop/entities/cti/graphql/subscriptions/ctiSidebarUpdates.api.ts'

import { useCallerNotificationToggle } from './useCallerNotificationToggle.ts'
import { useCtiAccess } from './useCtiAccess.ts'

export const useCtiSidebar = () => {
  const { isIntegrationEnabled } = useCtiAccess()

  const { isEnabled: isNotificationEnabled, setEnabled: setNotificationEnabled } =
    useCallerNotificationToggle()

  const sidebarQuery = new QueryHandler(
    useCtiSidebarQuery(() => ({
      enabled: isIntegrationEnabled.value,
      fetchPolicy: 'cache-and-network',
    })),
    {
      // A counter in the navigation is no place for an error notification.
      errorCallback: () => false,
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
      const sidebar = subscriptionData.data?.ctiSidebarUpdates.sidebar

      if (!sidebar) return previous

      return { ctiSidebar: sidebar }
    },
  })

  const sidebarResult = sidebarQuery.result()

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
    unhandledCount,
    ringingCalls,
    isNotificationEnabled,
    setNotificationEnabled,
  }
}
