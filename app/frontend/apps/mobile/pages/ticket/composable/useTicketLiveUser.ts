// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref, ComputedRef } from 'vue'
import { ref, onBeforeUnmount, watch } from 'vue'
import type {
  TicketById,
  TicketLiveAppUser,
} from '@shared/entities/ticket/types'
import {
  MutationHandler,
  SubscriptionHandler,
} from '@shared/server/apollo/handler'
import { EnumTaskbarApp } from '@shared/graphql/types'
import type { TicketLiveUser } from '@shared/graphql/types'
import { useAppName } from '@shared/composables/useAppName'
import { useSessionStore } from '@shared/stores/session'
import { useTicketLiveUserUpsertMutation } from '../graphql/mutations/live-user/ticketLiveUserUpsert.api'
import { useTicketLiveUserDeleteMutation } from '../graphql/mutations/live-user/delete.api'
import { useTicketLiveUserUpdatesSubscription } from '../graphql/subscriptions/live-user/ticketLiveUserUpdates.api'

export const useTicketLiveUser = (
  ticket: Ref<TicketById | undefined>,
  isTicketAgent: ComputedRef<boolean>,
  canSubmitForm: ComputedRef<boolean>,
) => {
  const liveUserList = ref<TicketLiveAppUser[]>([])
  const upsertMutation = new MutationHandler(useTicketLiveUserUpsertMutation())
  const deleteMutation = new MutationHandler(useTicketLiveUserDeleteMutation())

  const { userId } = useSessionStore()

  const updateLiveUser = async (editing = false) => {
    if (!ticket.value) return

    await upsertMutation.send({
      id: ticket.value.id,
      editing,
      app: EnumTaskbarApp.Mobile,
    })
  }

  const deleteLiveUser = async () => {
    if (!ticket.value) return

    await deleteMutation.send({
      id: ticket.value?.id,
      app: EnumTaskbarApp.Mobile,
    })
  }

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

  const liveUserSubscritionEnabled = ref(false)

  const liveUserSubscription = new SubscriptionHandler(
    useTicketLiveUserUpdatesSubscription(
      () => ({
        userId,
        key: `Ticket-${ticket.value?.internalId}`,
        app: EnumTaskbarApp.Mobile,
      }),
      () => ({
        // We need to disable the cache here, because otherwise we have the following error, when
        // a ticket is open again which is already in the subscription cache:
        // "ApolloError: 'get' on proxy: property 'liveUsers' is a read-only and non-configurable data property on the proxy target but the proxy did not return its actual value (expected '[object Array]' but got '[object Array]')"
        // At the end a cache for the subscription is not really needed, but we should create an issue on
        // apollo client side, when we have a minimal reproduction.
        fetchPolicy: 'no-cache',
        enabled: liveUserSubscritionEnabled.value && isTicketAgent.value,
      }),
    ),
  )

  liveUserSubscription.onResult((result) => {
    liveUserList.value = updateLiveUserList(
      (result.data?.ticketLiveUserUpdates.liveUsers as TicketLiveUser[]) || [],
    )
  })

  watch(
    () => ticket.value?.id,
    async (ticketId, oldTicketId) => {
      if (oldTicketId && ticketId !== oldTicketId) {
        liveUserList.value = []
        await deleteLiveUser()
      }

      await updateLiveUser()

      // Enable subscription, after ticket id is present.
      if (!liveUserSubscritionEnabled.value)
        liveUserSubscritionEnabled.value = true
    },
  )

  // Update live user editing status, when can submit value changes
  watch(canSubmitForm, async (canSubmit) => {
    await updateLiveUser(canSubmit)
  })

  onBeforeUnmount(async () => {
    await deleteLiveUser()
  })

  return {
    liveUserList,
  }
}
