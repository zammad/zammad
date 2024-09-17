// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { noop } from '@vueuse/shared'
import { type Ref, type ComputedRef, onBeforeMount } from 'vue'
import { watch } from 'vue'
import { onBeforeRouteLeave, onBeforeRouteUpdate } from 'vue-router'

import { useTicketLiveUserList } from '#shared/entities/ticket/composables/useTicketLiveUserList.ts'
import { EnumTaskbarApp } from '#shared/graphql/types.ts'
import { ensureGraphqlId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketLiveUserDeleteMutation } from '../graphql/mutations/live-user/delete.api.ts'
import { useTicketLiveUserUpsertMutation } from '../graphql/mutations/live-user/ticketLiveUserUpsert.api.ts'

export const useTicketLiveUser = (
  ticketInternalId: Ref<string>,
  isTicketAgent: ComputedRef<boolean>,
  editingForm: ComputedRef<boolean>,
) => {
  const { liveUserList } = useTicketLiveUserList(
    ticketInternalId,
    isTicketAgent,
    EnumTaskbarApp.Mobile,
  )

  const upsertMutation = new MutationHandler(useTicketLiveUserUpsertMutation())
  const deleteMutation = new MutationHandler(useTicketLiveUserDeleteMutation())

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
