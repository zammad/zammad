// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { ref, markRaw } from 'vue'
import { useRouter } from 'vue-router'

import {
  useNotifications,
  NotificationTypes,
} from '#shared/components/CommonNotifications/index.ts'
import { useConfirmation } from '#shared/composables/useConfirmation.ts'
import { useTicketMergeMutation } from '#shared/entities/ticket/graphql/mutations/merge.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import UserError from '#shared/errors/UserError.ts'
import type { AutocompleteSearchMergeTicketEntry } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

import { useDialog } from '#mobile/composables/useDialog.ts'

import TicketMergeStatus from '../components/TicketDetailView/TicketMergeStatus.vue'
import { AutocompleteSearchMergeTicketDocument } from '../graphql/queries/autocompleteSearchMergeTicket.api.ts'

import type { FormKitNode } from '@formkit/core'
import type { Ref } from 'vue'

export const useTicketsMerge = (
  sourceTicket: Ref<TicketById>,
  onSuccess?: () => void,
) => {
  const autocompleteRef = ref<{ node: FormKitNode }>()
  const ticketsSearchDialog = useDialog({
    name: 'tickets-search',
    prefetch: true,
    component: () =>
      import(
        '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInputDialog.vue'
      ),
  })

  const mergeHandler = new MutationHandler(useTicketMergeMutation({}))

  const { notify } = useNotifications()
  const router = useRouter()

  let localOptions: Record<string, AutocompleteSearchMergeTicketEntry> = {}

  const { waitForConfirmation } = useConfirmation()

  const mergeTickets = async () => {
    const context = autocompleteRef.value?.node.context
    if (!context || mergeHandler.loading().value) return false

    const targetTicketId = context._value
    const targetTicketOption = localOptions[targetTicketId]

    if (!targetTicketId || !targetTicketOption) {
      notify({
        id: 'merge-ticket-error',
        type: NotificationTypes.Error,
        message: __('Please select a ticket to merge into.'),
      })
      return false
    }
    const targetTicket = targetTicketOption.ticket

    const confirmed = await waitForConfirmation(
      __('Are you sure you want to merge this ticket (#%s) into #%s?'),
      {
        textPlaceholder: [sourceTicket.value.number, targetTicket.number],
      },
    )

    if (!confirmed) return false

    try {
      const result = await mergeHandler.send({
        sourceTicketId: sourceTicket.value.id,
        targetTicketId,
      })
      if (!result) {
        return false
      }
      context.node.input(undefined)
      router.push(`/tickets/${targetTicket.internalId}`)
      return true
    } catch (errors) {
      if (errors instanceof UserError) {
        notify({
          id: 'merge-ticket-error',
          message: errors.generalErrors[0],
          type: NotificationTypes.Error,
        })
      }
    }
    return false
  }

  const mergeAndCloseModals = async () => {
    const isMerged = await mergeTickets()
    if (isMerged) {
      ticketsSearchDialog.close()
      onSuccess?.()
    }
  }

  const openMergeTicketsDialog = () => {
    const context = autocompleteRef.value?.node.context

    if (!context) return

    Object.assign(context, {
      onActionClick: mergeAndCloseModals,
    })

    ticketsSearchDialog.open({
      context,
      name: 'tickets-search',
      options: [],
      optionIconComponent: markRaw(TicketMergeStatus),
      noCloseOnSelect: true,
      onUpdateOptions(options: AutocompleteSearchMergeTicketEntry[]) {
        localOptions = keyBy(options, 'value')
      },
      onAction() {
        mergeAndCloseModals()
      },
    })
  }

  return {
    gqlQuery: AutocompleteSearchMergeTicketDocument,
    autocompleteRef,
    openMergeTicketsDialog,
  }
}
