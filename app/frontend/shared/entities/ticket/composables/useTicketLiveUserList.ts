// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type Ref, type ComputedRef } from 'vue'
import { ref } from 'vue'

import { useAppName } from '#shared/composables/useAppName.ts'
import { useTicketLiveUserUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketLiveUserUpdates.api.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import type { TicketLiveUser } from '#shared/graphql/types.ts'
import { SubscriptionHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

export const useTicketLiveUserList = (
  ticketInternalId: Ref<string>,
  isTicketAgent: ComputedRef<boolean>,
  app: EnumTaskbarApp,
) => {
  const liveUserList = ref<TicketLiveAppUser[]>([])

  const { userId } = useSessionStore()

  const appName = useAppName()

  const updateLiveUserList = (liveUsers: TicketLiveUser[]) => {
    const mappedLiveUsers: TicketLiveAppUser[] = []

    liveUsers.forEach((liveUser) => {
      let appItems = liveUser.apps.filter((data) => data.editing)

      // Skip own live user item, when it's holds only the current app and is not editing on the other one.
      if (liveUser.user.id === userId) {
        if (appItems.length === 0) return

        appItems = appItems.filter((item) => item.name !== appName)

        if (appItems.length === 0) return
      }

      if (appItems.length === 0) {
        appItems = liveUser.apps
      }

      // Sort app items by last interaction.
      appItems.sort((a, b) => {
        return (
          new Date(b.lastInteraction).getTime() -
          new Date(a.lastInteraction).getTime()
        )
      })

      mappedLiveUsers.push({
        user: liveUser.user,
        ...appItems[0],
        app: appItems[0].name,
      })
    })

    return mappedLiveUsers
  }

  const liveUserSubscription = new SubscriptionHandler(
    useTicketLiveUserUpdatesSubscription(
      () => ({
        userId,
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

  liveUserSubscription.onResult((result) => {
    liveUserList.value = updateLiveUserList(
      (result.data?.ticketLiveUserUpdates.liveUsers as TicketLiveUser[]) || [],
    )
  })

  return {
    liveUserList,
  }
}
