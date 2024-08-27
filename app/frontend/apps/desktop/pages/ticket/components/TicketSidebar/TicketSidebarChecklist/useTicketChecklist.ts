// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type {
  TicketChecklistQuery,
  TicketChecklistUpdatesSubscription,
  TicketChecklistUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.api.ts'
import { TicketChecklistUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.api.ts'

export const useTicketChecklist = () => {
  const { ticket, ticketId } = useTicketInformation()

  const readonly = computed(() => !ticket?.value?.policy.update)

  const checklistQuery = new QueryHandler(
    useTicketChecklistQuery(() => ({
      ticketId: ticketId.value,
    })),
  )

  const checklistResult = checklistQuery.result()
  const checklistLoading = checklistQuery.loading()

  const checklist = computed(() => checklistResult.value?.ticketChecklist)

  const isLoadingChecklist = computed(() => {
    // Return true when the ticket is not loaded yet, because some output is related to the ticket data (e.g. readonly).
    if (!ticket.value) return true

    // Return already true when an checklist result already exists from the cache, also
    // when maybe a loading is in progress(because of cache + network).
    if (checklist.value !== undefined) return false

    return checklistLoading.value
  })

  const incompleteItemCount = computed(
    () => checklistResult.value?.ticketChecklist?.incomplete,
  )

  checklistQuery.subscribeToMore<
    TicketChecklistUpdatesSubscriptionVariables,
    TicketChecklistUpdatesSubscription
  >(() => ({
    document: TicketChecklistUpdatesDocument,
    variables: {
      ticketId: ticketId.value,
    },
    updateQuery: (prev, { subscriptionData }) => {
      if (
        !subscriptionData.data.ticketChecklistUpdates.ticketChecklist &&
        !subscriptionData.data.ticketChecklistUpdates.removedTicketChecklist
      ) {
        return null as unknown as TicketChecklistQuery
      }

      const { ticketChecklist, removedTicketChecklist } =
        subscriptionData.data.ticketChecklistUpdates

      // When a complete checklist was removed, we need to update the result.
      if (
        removedTicketChecklist ||
        (prev.ticketChecklist === null && ticketChecklist !== null)
      ) {
        return {
          ticketChecklist,
        }
      }

      // Always return null when we need not to change anything related to the data.
      return null as unknown as TicketChecklistQuery
    },
  }))

  return {
    checklist,
    incompleteItemCount,
    readonly,
    isLoadingChecklist,
  }
}
