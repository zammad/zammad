// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

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
  const checklistLoading = checklistQuery.loadingWithoutCachedResult()

  const checklist = computed(() => checklistResult?.value?.ticketChecklist as Checklist)

  const incompleteItemCount = computed(() => checklist.value?.incomplete)

  return {
    checklist,
    incompleteItemCount,
    isLoadingChecklist: checklistLoading,
  }
}
