// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { type Ref, type ComputedRef } from 'vue'

import { useTaskbarLiveUserList } from '#shared/entities/taskbar/composables/useTaskbarLiveUserList.ts'
import { useTicketLiveUserUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketLiveUserUpdates.api.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'

export const useTicketLiveUserList = (
  ticketInternalId: Ref<string>,
  isTicketAgent: ComputedRef<boolean>,
  app: EnumTaskbarApp,
) => {
  const liveUserSubscription = new SubscriptionHandler(
    useTicketLiveUserUpdatesSubscription(
      () => ({
        key: `Ticket-${ticketInternalId.value}`,
        app,
      }),
      () => ({
        // We need to disable the cache here, because otherwise we have the following error, when
        // a ticket is open again which is already in the subscription cache:
        // "ApolloError: 'get' on proxy: property 'liveUsers' is a read-only and non-configurable data property on the proxy target but the proxy did not return its actual value (expected '[object Array]' but got '[object Array]')"
        // At the end a cache for the subscription is not really needed, but we should create an issue on
        // apollo client side, when we have a minimal reproduction.
        fetchPolicy: 'no-cache',
        enabled: isTicketAgent.value,
      }),
    ),
  )

  return useTaskbarLiveUserList(
    liveUserSubscription,
    (data) => data.ticketLiveUserUpdates.liveUsers || [],
  )
}
