// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { noop } from '@vueuse/shared'
import { type Ref, type ComputedRef, onBeforeMount } from 'vue'
import { ref, watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

import { useAppName } from '#shared/composables/useAppName.ts'
import type { TicketLiveAppUser } from '#shared/entities/ticket/types.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import type { TicketLiveUser } from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'
import {
  MutationHandler,
  SubscriptionHandler,
} from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import { useTicketLiveUserDeleteMutation } from '../graphql/mutations/live-user/delete.api.ts'
import { useTicketLiveUserUpsertMutation } from '../graphql/mutations/live-user/ticketLiveUserUpsert.api.ts'
import { useTicketLiveUserUpdatesSubscription } from '../graphql/subscriptions/live-user/ticketLiveUserUpdates.api.ts'

export const useTicketLiveUser = (
  ticketInternalId: Ref<string>,
  isTicketAgent: ComputedRef<boolean>,
  editingForm: ComputedRef<boolean>,
) => {
  const liveUserList = ref<TicketLiveAppUser[]>([])
  const upsertMutation = new MutationHandler(useTicketLiveUserUpsertMutation())
  const deleteMutation = new MutationHandler(useTicketLiveUserDeleteMutation())

  const { userId } = useSessionStore()

  const updateLiveUser = async (ticketInternalId: string, editing = false) => {
    await upsertMutation
      .send({
        id: ensureGraphqlId('Ticket', ticketInternalId),
        editing,
        app: EnumTaskbarApp.Mobile,
      })
      .catch(noop)
  }

  const deleteLiveUser = async (ticketInternalId: string) => {
    await deleteMutation
      .send({
        id: ensureGraphqlId('Ticket', ticketInternalId),
        app: EnumTaskbarApp.Mobile,
      })
      .catch(noop)
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

  const liveUserSubscription = new SubscriptionHandler(
    useTicketLiveUserUpdatesSubscription(
      () => ({
        userId,
        key: `Ticket-${ticketInternalId.value}`,
        app: EnumTaskbarApp.Mobile,
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

  onBeforeRouteUpdate(async (to, from) => {
    const internalToId = to.params.internalId as string
    const internalFromId = from.params.internalId as string

    // update status when opening another ticket page without unmounting the page and don't block the page
    if (internalToId !== internalFromId) {
      liveUserList.value = []
      deleteLiveUser(internalFromId)
      updateLiveUser(internalToId)
    }
  })

  onBeforeRouteLeave(async (_, from) => {
    const internalId = from.params.internalId as string

    // update status when leaving to non-ticket page, but don't block the page
    deleteLiveUser(internalId)
  })

  onBeforeMount(async () => {
    // update status on opening the page. it is possible that this code will run,
    // when user doesn't have access to the ticket, because we fail after the route is rendered
    await updateLiveUser(ticketInternalId.value)
  })

  // Update live user editing status, when can submit value changes
  watch(editingForm, async (canSubmit) => {
    await updateLiveUser(ticketInternalId.value, canSubmit)
  })

  return {
    liveUserList,
  }
}
