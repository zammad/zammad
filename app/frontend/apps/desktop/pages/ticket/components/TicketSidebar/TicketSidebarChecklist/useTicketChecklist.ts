// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type {
  ChecklistItem,
  TicketChecklistQuery,
  TicketChecklistUpdatesSubscription,
  TicketChecklistUpdatesSubscriptionVariables,
} from '#shared/graphql/types.ts'
import { QueryHandler } from '#shared/server/apollo/handler/index.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'
import { useTicketChecklistQuery } from '#desktop/pages/ticket/graphql/queries/ticketChecklist.api.ts'
import { TicketChecklistUpdatesDocument } from '#desktop/pages/ticket/graphql/subscriptions/ticketChecklistUpdates.api.ts'

export const useTicketChecklist = (
  subscriptionUpdateCallback?: (
    previousChecklist: ChecklistItem[],
    newChecklist: ChecklistItem[],
  ) => void,
) => {
  const { ticketId, ticket } = useTicketInformation()

  const readOnly = computed(() => !ticket.value?.policy.update)

  const checklistQuery = new QueryHandler(
    useTicketChecklistQuery(() => ({
      ticketId: ticketId.value,
    })),
    {
      errorCallback: (error) => error.type !== GraphQLErrorTypes.RecordNotFound,
    },
  )

  const checklistResult = checklistQuery.result()
  const checklistLoading = checklistQuery.loading()

  const checklist = computed(() => checklistResult.value?.ticketChecklist)

  const isLoadingChecklist = computed(() => {
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
      ticketId: ticketId.value as string,
    },
    updateQuery: (prev, { subscriptionData }) => {
      if (!subscriptionData.data.ticketChecklistUpdates)
        return null as unknown as TicketChecklistQuery

      const { ticketChecklist } = subscriptionData.data.ticketChecklistUpdates

      if (
        checklist.value?.items?.length &&
        ticketChecklist?.items?.length &&
        subscriptionUpdateCallback
      )
        subscriptionUpdateCallback(
          checklistResult.value?.ticketChecklist?.items as ChecklistItem[],
          ticketChecklist.items as ChecklistItem[],
        )

      // When a complete checklist was removed, we need to update the result.
      if (
        ticketChecklist === null ||
        (prev.ticketChecklist === null && ticketChecklist !== null)
      ) {
        return {
          ticketChecklist,
        }
      }

      // Always return null, because we need not to manipulate the data with this function. It's only for handling the
      //  edit mode callback.
      return null as unknown as TicketChecklistQuery
    },
  }))

  return {
    checklist,
    incompleteItemCount,
    readOnly,
    isLoadingChecklist,
  }
}
