// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import type {
  Checklist,
  TicketChecklistQuery,
  TicketChecklistUpdatesSubscription,
  TicketChecklistUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'

import { useTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.api.ts'
import { TicketChecklistUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.api.ts'

export const useTicketChecklist = (
  /**
   * TicketId is always available since we use it from the route not `ticket` directly
   */
  ticketId: ComputedRef<string>,
  ticket: ComputedRef<TicketById | undefined>,
) => {
  const checklistQuery = new QueryHandler(
    useTicketChecklistQuery(() => ({
      ticketId: ticketId.value,
    })),
  )

  checklistQuery.subscribeToMore<
    TicketChecklistUpdatesSubscriptionVariables,
    TicketChecklistUpdatesSubscription
  >(() => ({
    document: TicketChecklistUpdatesDocument,
    variables: {
      ticketId: ticketId.value,
    },
    updateQuery: (_, { previousData, subscriptionData }) => {
      if (
        !subscriptionData.data.ticketChecklistUpdates.ticketChecklist &&
        !subscriptionData.data.ticketChecklistUpdates.removedTicketChecklist
      ) {
        return null as unknown as TicketChecklistQuery
      }

      const { ticketChecklist } = subscriptionData.data.ticketChecklistUpdates

      // When a complete checklist was removed, we need to update the result.
      if (!ticketChecklist || previousData?.ticketChecklist === null) {
        return {
          ticketChecklist,
        }
      }

      // Always return null when we need not change anything related to the data.
      return null as unknown as TicketChecklistQuery
    },
  }))

  const checklistResult = checklistQuery.result()
  const checklistLoading = checklistQuery.loading()

  const checklist = computed(
    () => checklistResult?.value?.ticketChecklist as Checklist,
  )

  const isLoadingChecklist = computed(() => {
    // Return true when the ticket is not loaded yet, because some output is related to the ticket data (e.g. readonly).

    if (!ticket.value) return true

    // Return already true when a checklist result already exists from the cache, also
    // when maybe a loading is in progress(because of cache + network).
    if (checklist.value !== undefined) return false

    return checklistLoading.value
  })

  const incompleteItemCount = computed(() => checklist.value?.incomplete)

  return {
    checklist,
    incompleteItemCount,
    isLoadingChecklist,
  }
}
