// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { Ref, ComputedRef } from 'vue'
import { ref, onBeforeUnmount, watch } from 'vue'
import type { TicketById } from '@shared/entities/ticket/types'
import {
  MutationHandler,
  SubscriptionHandler,
} from '@shared/server/apollo/handler'
import { EnumTaskbarApp } from '@shared/graphql/types'
import type {
  TicketLiveUser,
  TicketLiveUserUpdatesSubscription,
  TicketLiveUserUpdatesSubscriptionVariables,
} from '@shared/graphql/types'
import { useSessionStore } from '@shared/stores/session'
import { useTicketLiveUserUpsertMutation } from '../graphql/mutations/live-user/ticketLiveUserUpsert.api'
import { useTicketLiveUserDeleteMutation } from '../graphql/mutations/live-user/delete.api'
import { useTicketLiveUserUpdatesSubscription } from '../graphql/subscriptions/live-user/ticketLiveUserUpdates.api'

export const useTicketLiveUser = (
  ticket: Ref<TicketById | undefined>,
  canSubmitForm: ComputedRef<boolean>,
) => {
  const liveUserList = ref<TicketLiveUser[]>([])
  const upsertMutation = new MutationHandler(useTicketLiveUserUpsertMutation())
  const deleteMutation = new MutationHandler(useTicketLiveUserDeleteMutation())

  const { userId } = useSessionStore()

  let liveUserSubscription: SubscriptionHandler<
    TicketLiveUserUpdatesSubscription,
    TicketLiveUserUpdatesSubscriptionVariables
  >

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

  watch(
    () => ticket.value?.id,
    async (ticketId, oldTicketId) => {
      if (oldTicketId && ticketId !== oldTicketId) {
        liveUserList.value = []
        await deleteLiveUser()
      }

      await updateLiveUser()

      if (!liveUserSubscription) {
        liveUserSubscription = new SubscriptionHandler(
          useTicketLiveUserUpdatesSubscription(
            () => ({
              userId,
              key: `Ticket-${ticket.value?.internalId}`,
              app: EnumTaskbarApp.Mobile,
            }),
            {
              // We need to disable the cache here, because otherwise we have the following error, when
              // a ticket is open again which is already in the subscription cache:
              // "ApolloError: 'get' on proxy: property 'liveUsers' is a read-only and non-configurable data property on the proxy target but the proxy did not return its actual value (expected '[object Array]' but got '[object Array]')"
              // At the end a cache for the subscription is not really needed, but we should create an issue on
              // apollo client side, when we have a minimal reproduction.
              fetchPolicy: 'no-cache',
            },
          ),
        )

        liveUserSubscription.onResult((result) => {
          liveUserList.value =
            (result.data?.ticketLiveUserUpdates
              .liveUsers as TicketLiveUser[]) || []
        })
      }
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
