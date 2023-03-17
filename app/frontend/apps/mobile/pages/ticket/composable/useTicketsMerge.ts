// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import useConfirmation from '@mobile/components/CommonConfirmation/composable'
import {
  useNotifications,
  NotificationTypes,
} from '@shared/components/CommonNotifications'
import { useDialog } from '@shared/composables/useDialog'
import UserError from '@shared/errors/UserError'
import { MutationHandler } from '@shared/server/apollo/handler'
import type { Ref } from 'vue'
import { ref, markRaw } from 'vue'
import { useRouter } from 'vue-router'
import { useTicketMergeMutation } from '@shared/entities/ticket/graphql/mutations/merge.api'
import type { AutocompleteSearchMergeTicketEntry } from '@shared/graphql/types'
import { keyBy } from 'lodash-es'
import type { TicketById } from '@shared/entities/ticket/types'
import { AutocompleteSearchMergeTicketDocument } from '../graphql/queries/autocompleteSearchMergeTicket.api'
import TicketMergeStatus from '../components/TicketDetailView/TicketMergeStatus.vue'

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
        '@shared/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInputDialog.vue'
      ),
  })

  const mergeHandler = new MutationHandler(useTicketMergeMutation({}))

  const { notify } = useNotifications()
  const router = useRouter()

  const { waitForConfirmation } = useConfirmation()

  let localOptions: Record<string, AutocompleteSearchMergeTicketEntry> = {}

  const mergeTickets = async () => {
    const context = autocompleteRef.value?.node.context
    if (!context || mergeHandler.loading().value) return false

    const targetTicketId = context._value
    const targetTicketOption = localOptions[targetTicketId]

    if (!targetTicketId || !targetTicketOption) {
      notify({
        type: NotificationTypes.Error,
        message: __('Please select a ticket to merge into.'),
      })
      return false
    }
    const targetTicket = targetTicketOption.ticket

    const confirmed = await waitForConfirmation(
      __('Are you sure you want to merge this ticket (#%s) into #%s?'),
      {
        headingPlaceholder: [sourceTicket.value.number, targetTicket.number],
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
